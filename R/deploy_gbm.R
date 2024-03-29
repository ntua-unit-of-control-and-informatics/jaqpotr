#' Deploy Generalized Boosted Regression Models (GBM) on Jaqpot
#'
#' Uploads a trained GBM model on Jaqpot given a "gbm" object.
#'
#'
#' @param object An object of class "gbm" (function \code{gbm()} of package 'gbm').
#'  @param replace used for NA substitution with a desired numeric value. 
#' @param url The base path of Jaqpot services. This argument is optional and needs
#' to be changed only if an alternative Jaqpot installation is used.
#' @return  The id of the uploaded model.
#' @details The user can upload on Jaqpot a model that has been trained using the
#'   \code{gbm()} function of package 'gbm'. Apart from the model object, the user is requested
#'  to provide further information (i.e. Jaqpot API key or credentials, model title and short
#'  description) via prompt messages. If the upload process is successful,
#'  the user is given a unique model id key.
#'
#' @examples
#'  \dontrun{
#'  #gbm.model <- gbm::gbm(y~x, data=df)
#'  #deploy.gbm(gbm.model)
#'  }
#'
#' @export
deploy.gbm <- function(object, replace = NULL, url = "https://api.jaqpot.org/jaqpot/"){

  # Get object class
  obj.class <- attributes(object)$class[1] # class of glm models is "glm" "lm"
  # If object not an gbm through error
  if  ( (obj.class != "gbm")){
    stop("Model should be of class 'gbm' ")
  }
  
  # Check if replace is provided that it is numeric
  if(!is.null(replace)){
    if ( !is.numeric(replace)){
      stop("Please provide a numeric value for NA replacement")
    }
  }

  # Read the base path from the reader
   base.path <- url
  # Log into Jaqpot using the LoginJaqpot helper function in utils.R
  token <- jaqpot.token
  # Ask the user for a a model title
  title <- readline("Title of the model: ")
  # Ask the user for a short model description
  description <- readline("Short description of the model: ")

  independent.vars <- object$var.names
  # Retrieve predicted variables by using set difference
  dependent.vars <- object$response.name
  # Delete attributes that are not necessary in the prediction process and increase object size
  object$train.error <- NULL
  object$valid.error <- NULL
  object$fit <- NULL
  # Serialize the model in order to upload it on Jaqpot
  model <- serialize(list(MODEL=object),connection=NULL)
  # Create a list containing the information that will be uploaded on Jaqpot
  tojson <- list(rawModel=model, runtime="R-gbm", implementedWith="gbm tree in R",
                 pmmlModel=NULL, independentFeatures=independent.vars,
                 predictedFeatures=dependent.vars, dependentFeatures=dependent.vars,
                 title=title, description=description, algorithm="R/tree/gmb",additionalInfo = list(replace = replace))
  # Convert the list to a JSON data format
  tryCatch({
    json <- jsonlite::toJSON(tojson)
    }, error = function(e) {
          e$message <-"Failed to convert object to json. "
          stop(e)
    })
  # Function that posts the model on Jaqpot
  .PostOnService(base.path, token, json)
}
