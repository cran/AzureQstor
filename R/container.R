#' Message queues
#'
#' Get, list, create, or delete queues.
#'
#' @param endpoint Either a queue endpoint object as created by [AzureStor::storage_endpoint], or a character string giving the URL of the endpoint.
#' @param key,token,sas If an endpoint object is not supplied, authentication credentials: either an access key, an Azure Active Directory (AAD) token, or a SAS, in that order of priority.
#' @param api_version If an endpoint object is not supplied, the storage API version to use when interacting with the host. Currently defaults to `"2019-07-07"`.
#' @param name The name of the queue to get, create, or delete.
#' @param confirm For deleting a queue, whether to ask for confirmation.
#' @param ... Further arguments passed to lower-level functions.
#'
#' @details
#' You can call these functions in a couple of ways: by passing the full URL of the storage queue, or by passing the endpoint object and the name of the share as a string.
#'
#' @return
#' For `storage_queue` and `create_storage_queue`, an object of class [`StorageQueue`]. For `list_storage_queues`, a list of such objects.
#'
#' @seealso
#' [`StorageQueue`], [`queue_endpoint`]
#' @examples
#' \dontrun{
#'
#' endp <- storage_endpoint("https://mystorage.queue.core.windows.net", key="key")
#'
#' # to talk to an existing queue
#' queue <- storage_queue(endp, "queue1")
#'
#' # to create a new queue
#' queue2 <- create_storage_queue(endp, "queue2")
#'
#' # various ways to delete a queue (will ask for confirmation first)
#' queue2$delete()
#' delete_storage_queue(queue2)
#' delete_storage_queue(endp, "queue2")
#' }
#' @rdname queue
#' @export
storage_queue <- function(endpoint, ...)
{
    UseMethod("storage_queue")
}

#' @rdname queue
#' @export
storage_queue.character <- function(endpoint, key=NULL, token=NULL, sas=NULL,
                                    api_version=getOption("azure_storage_api_version"),
                                    ...)
{
    do.call(storage_queue, generate_endpoint_container(endpoint, key, token, sas, api_version))
}

#' @rdname queue
#' @export
storage_queue.queue_endpoint <- function(endpoint, name, ...)
{
    StorageQueue$new(endpoint, name)
}


#' @rdname queue
#' @export
list_storage_queues <- function(endpoint, ...)
{
    UseMethod("list_storage_queues")
}

#' @rdname queue
#' @export
list_storage_queues.character <- function(endpoint, key=NULL, token=NULL, sas=NULL,
                                          api_version=getOption("azure_storage_api_version"),
                                          ...)
{
    do.call(list_storage_queues, generate_endpoint_container(endpoint, key, token, sas, api_version))
}

#' @rdname queue
#' @export
list_storage_queues.queue_endpoint <- function(endpoint, ...)
{
    res <- call_storage_endpoint(endpoint, "/", options=list(comp="list"))
    lst <- lapply(res$Queue, function(cont) storage_queue(endpoint, cont$Name[[1]]))

    while(length(res$NextMarker) > 0)
    {
        res <- call_storage_endpoint(endpoint, "/", options=list(comp="list", marker=res$NextMarker[[1]]))
        lst <- c(lst, lapply(res$Queue, function(cont) storage_queue(endpoint, cont$Name[[1]])))
    }
    named_list(lst)
}

#' @rdname queue
#' @export
list_storage_containers.queue_endpoint <- function(endpoint, ...)
list_storage_queues(endpoint, ...)



#' @rdname queue
#' @export
create_storage_queue <- function(endpoint, ...)
{
    UseMethod("create_storage_queue")
}

#' @rdname queue
#' @export
create_storage_queue.character <- function(endpoint, key=NULL, token=NULL, sas=NULL,
                                           api_version=getOption("azure_storage_api_version"),
                                           ...)
{
    endp <- generate_endpoint_container(endpoint, key, token, sas, api_version)
    create_storage_queue(endp$endpoint, endp$name, ...)
}

#' @rdname queue
#' @export
create_storage_queue.queue_endpoint <- function(endpoint, name, ...)
{
    obj <- storage_queue(endpoint, name)
    create_storage_queue(obj)
}

#' @rdname queue
#' @export
create_storage_queue.StorageQueue <- function(endpoint, ...)
{
    endpoint$create()
}



#' @rdname queue
#' @export
delete_storage_queue <- function(endpoint, ...)
{
    UseMethod("delete_storage_queue")
}

#' @rdname queue
#' @export
delete_storage_queue.character <- function(endpoint, key=NULL, token=NULL, sas=NULL,
                                           api_version=getOption("azure_storage_api_version"),
                                           ...)
{
    endp <- generate_endpoint_container(endpoint, key, token, sas, api_version)
    delete_storage_queue(endp$endpoint, endp$name, ...)
}

#' @rdname queue
#' @export
delete_storage_queue.queue_endpoint <- function(endpoint, name, ...)
{

    obj <- storage_queue(endpoint, name)
    delete_storage_queue(obj, ...)
}

#' @rdname queue
#' @export
delete_storage_queue.StorageQueue <- function(endpoint, confirm=TRUE, ...)
{
    endpoint$delete(confirm=confirm)
}

