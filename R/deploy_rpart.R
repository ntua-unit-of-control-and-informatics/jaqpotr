#' Deploy  Classification  and Regression Tree Models on Jaqpot
#'
#' Uploads trained rpart tree regression and classification models on Jaqpot given
#' an "rpart" object.
#'
#' @param object An object of class "rpart" (function \code{rpart()} of package 'rpart').
#' @param replace used for NA substitution with a desired numeric value.
#' @param url The base path of Jaqpot services. This argument is optional and needs 
#' to be changed only if an alternative Jaqpot installation is used.
#' @return  The id of the uploaded model.
#' @details The user can upload on Jaqpot an rpart model that has been trained using the
#'  function \code{rpart()} of package 'rpart'. Apart from the model object, the user is requested
#'  to provide further information (i.e. Jaqpot API key or credentials, model title and short
#'  description) via prompt messages. If the upload process is successful,
#'  the user is given a unique model id key.
#'
#' @examples
#'  \dontrun{
#'  #rpart.model <- rpart::rpart(y~x, data=df)
#'  #deploy.rpart(rpart.model)
#' }
#'
#' @export

deploy.rpart <- function(object, replace = NULL, url = "https://api.jaqpot.org/jaqpot/"){
  # Get object class
  obj.class <- attributes(object)$class[1] # class of glm models is "glm" "lm"
  # If object not an lm or glm through error
  if(obj.class != "rpart"){
    stop("Model should be of class 'rpart' ")
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

  independent.vars <- attributes(object$terms)$term.labels
  # Number of responses
  N_resp <-  attributes(object$terms)$response
  # All variables (dependent and independent)
  all_vars_init <- as.character(attributes(object$terms)$variables)
  all_vars <- all_vars_init[2:length(all_vars_init)]
  # Retrieve predicted variables by using set difference
  dependent.vars <- setdiff(all_vars, independent.vars)

  # Delete attributes that are not necessary in the prediction process and increase object size
  #object$where <- NULL
  #object$call <- NULL
  #object$cptable <- NULL
  #object$control <- NULL
  #object$functions <- NULL
  #object$variable.importance <- NULL
  # Serialize the model in order to upload it on Jaqpot
  model <- serialize(list(MODEL=object),connection=NULL)
  # Create a list containing the information that will be uploaded on Jaqpot
  tojson <- list(rawModel=model, runtime="R-rpart", implementedWith="R rpart",
                 pmmlModel=NULL, independentFeatures=independent.vars,
                 predictedFeatures=dependent.vars, dependentFeatures=dependent.vars,
                 title=title, description=description, algorithm="rpart tree",additionalInfo = list(replace = replace))
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
