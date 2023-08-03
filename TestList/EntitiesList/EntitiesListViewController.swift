import UIKit
import CoreData

class EntitiesListViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    let fetchContext: NSManagedObjectContext
    let writeContext: NSManagedObjectContext

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = MyEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: fetchContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()

        return fetchedResultsController
    }()

    // MARK: - Initialization

    init() {
        // The update of rows works only if fetch context is the same as write context
        // But we want to fetch data in background so we want to use view context for the fetched results controller and background contexts to do the import / update of objects
        // In our App we also create new background context for each import operation to reduce the memory footprint as NSManagedObjectContext is keeping cache of objects
        // Using parent context didn't solve the issue
        let container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        self.fetchContext = container.viewContext
        self.writeContext = container.newBackgroundContext()

        super.init(style: .plain)

        title = "List of items"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell
        tableView.register(EntityCell.self, forCellReuseIdentifier: "cell")

        Task {
            // Populate if empty
            await populateIfNecessary()

            // Update entities dates in a random way
            scheduleRandomizeEntitiesDates()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? "-"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let object = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = "\(object.identifier)"
        cell.detailTextLabel?.text = "\(fetchedResultsController.object(at: indexPath).updatedAt)"

        return cell
    }

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            //try? self.fetchedResultsController.performFetch()
            self.tableView.reloadData()
        }
    }

    // MARK: - Populating

    func populateIfNecessary() async {
        await writeContext.perform {
            let request = MyEntity.fetchRequest()
            if (try? self.writeContext.count(for: request)) == 0 {
                // Create 3000 entities
                for _ in 0...3000 {
                    let entity = MyEntity(context: self.writeContext)
                    entity.identifier = UUID()
                    entity.populateDate()
                }

                do {
                    try self.writeContext.save()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }

    func scheduleRandomizeEntitiesDates() {
        // Dispatch after 5 seconds
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5, execute: {
            Task { [weak self] in
                await self?.randomizeEntitiesDates()
            }
        })
    }

    func randomizeEntitiesDates() async {
        // Update the 3000 elements in 6 operations of 500 updates
        for i in 0...6 {
            // If I use the view context everything works fine, but with background context the sort aren't reflected correctly
            let context = self.writeContext
            await context.perform {
                let request = MyEntity.fetchRequest()
                request.fetchOffset = i * 500
                request.fetchLimit = 500

                do {
                    let entities = try context.fetch(request)
                    for entity in entities {
                        entity.populateDate()
                    }

                    try context.save()
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }

            sleep(2)
        }

        DispatchQueue.main.async {
            self.printFetchedResultsControllerFirstLines()
        }
    }

    func printFetchedResultsControllerFirstLines() {
        let lines = fetchedResultsController.fetchedObjects?[0...20].map {
            "\($0.identifier) - \($0.updatedAt)"
        }.joined(separator: "\n") ?? ""
        print(lines)
    }
}

