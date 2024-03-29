#' Deploy A caret model on Jaqpot
#'
#' Uploads trained caret model on Jaqpot given
#' a "train" object.
#'
#' @param trained.model An object of 'train' (function \code{train()} of package 'caret'). If an ensemble
#' of models is used, then the trained models should be enclosed in a list, with the same order as the one used in the ensemble
#' @param preprocess.model The preprocess model(s), with default value NULL.The model object(s) should be enclosed in a list. Consecutive
#'  preprocessing steps are supported by providing the consecutive preprocessing models with the same order in the list.
#'  DO NOT include the response into the preprocessing model! The preprocessing of the response should be done seperately and the
#'  detransformation step of the response is facilitated by the ymin, ymax, ymean and ystd arguments, depending on the preprocessing type used.
#' Allowed types of preprocessing: 'preProcess' and 'dummyVars' caret functions. 
#' @param ensemble.model The ensemble model, with default value NULL. Only applicable type is stacked ensemble. Note that if an ensemble model is used, 
#' then the order of the models in the list provided in 'trained.model' should be the same as the one used in the stacking process.
#' @param replace used for NA substitution with a desired value. It should be a list of two arguments, with the first being either "before" or "after", 
#' for doing the substitution before or after the preprocessing step, and the second list argument is the desired replacement value. The default
#' replacement is after the preprocessing step with the value of -100. 
#' @param ymin Minimum y value to be used for y detrasformation. This applies if y has been scaled using the \code{range} method of \code{preProcess()} function.
#' @param ymax Maximum y value to be used for y detrasformation. This applies if y has been scaled using the \code{range} method of \code{preProcess()} function.
#' @param ymean Mean of y to be used for y detrasformation. This applies if y has been scaled using the \code{c("center","scale")} method of \code{preProcess()} function.
#' @param ystd Standard deviation of y to be used for y detrasformation. This applies if y has been scaled using the \code{c("center","scale")} method of \code{preProcess()} function.
#' @param url The base path of Jaqpot services. This argument is optional and needs 
#' to be changed only if an alternative Jaqpot installation is used.
#' @param ... Extra arguments to be passed down the R client. This is not recommended.
#' @return  The id of the uploaded model.
#' @details The user can upload on Jaqpot a model that has been trained using the
#'  function \code{ctree()} of package 'party'. Apart from the model object, the user is requested
#'  to provide further information (i.e. Jaqpot API key or credentials, model title and short
#'  description etc.) via prompt messages. If the upload process is successful,
#'  the user is given a unique model id key.
#'
#' @examples
#'  \dontrun{
#'   #preprocessParams <- caret::preProcess(DATATrain, method=c("center","scale"))
#'   #DATATrainPre<-predict(preprocessParams, DATA1Train)
#'   dmyRTD<-dummyVars(~.,data=DATATrainPre)
#'   dmy_df<-predict(dmyRTD, newdata=DATATrainPre)
#'   #dmy_df[is.na(dmy_df)]<--20
#'   #trainControl<-trainControl(method="repeatedcv", number=20, repeats=3,verboseIter = FALSE,
#'   allowParallel = FALSE, savePredictions=TRUE)
#'   #fitXGB<-caret::train(y~., data =dmy_df, method="xgbTree", trControl=trainControl ,
#'                tuneGrid=tunegrid , importance=TRUE,verbosity=0) 
#'   #jaqpotr::deploy.caret(trained.model = fitXGB, preprocess.model = list(preprocessParams, dmyRTD), 
#'   replace = list("after", -20) )
#' }
#'
#' @export
deploy.caret <- function( trained.model, preprocess.model = NULL, ensemble.model = NULL, replace = list("after",-100), ymax =NULL, ymin =NULL, 
                          ymean =NULL, ystd =NULL, url = "https://api.jaqpot.org/jaqpot/", ...){
  
  # Make sure that preprocess.model is a list
  if ( !is.null(attributes(preprocess.model))){
    stop("Please enclose your preprocess model(s) in a list by using the list() function")
  }
  # If an ensemble model is provided, then the trained.model should be a list of models
  if(!is.null(ensemble.model)){
    if ( !is.null(attributes(trained.model))){
      stop("Please enclose your trained models in a list by using the list() function")
    }
  }

  
  # !!!!!!!!ATTENTION !!!!!!!!!!!!!!!!!
  # Check the model size here
  
  # Read the base path from the reader
  base.path <- url
  # Log into Jaqpot using the LoginJaqpot helper function in utils.R
  token <- jaqpot.token
  # Ask the user for a a model title
  title <- readline("Title of the model: ")
  # Ask the user for a short model description
  description <- readline("Short description of the model: ")
  
  # Obtain the library on which the model was built
  library <- trained.model$modelInfo$library[1]
  
  # Create a model replicate to draw the dependent variable names
  if(is.null(ensemble.model)){
    ModelForNames <- trained.model
    ensemble.vars <- NULL
  }else{
    ModelForNames <- trained.model[[1]]
    ensemble.vars <- array(attributes(ensemble.model$terms)$term.labels)
  }
  
  if (!is.null(preprocess.model)){
    # Different handling if first preprocess object is of class dummyVars or preProcess
    if(attributes(preprocess.model[[1]])$class == "dummyVars"){
      independent.vars <- preprocess.model[[1]]$vars
    }else if (attributes(preprocess.model[[1]])$class == "preProcess"){
      # Obtain the names of the variables from the variables on the method used, combined with the ignored variables 
      independent.vars  <- list()
      for (i in 1:length(preprocess.model[[1]]$method)){
        independent.vars[[i]] <- preprocess.model[[1]]$method[[i]]
      }
      independent.vars <- unlist(independent.vars)
      independent.vars <- unique(independent.vars)
    }
      #Retrieve the model independent vars (may contain variables resulting from one-hot encoding)
      model.independent.vars <- array(attributes(ModelForNames$terms)$term.labels)
      # Number of responses
      N_resp <-  attributes(ModelForNames$terms)$response
      # All variables (dependent and independent)
      all_vars_init <- as.character(attributes(ModelForNames$terms)$variables)
      all_vars <- all_vars_init[2:length(all_vars_init)]
      # Retrieve predicted variables by using set difference
      dependent.vars <- setdiff(all_vars, model.independent.vars)
    
    }else{
      #Retrieve the independent vars
      independent.vars <- array(attributes(ModelForNames$terms)$term.labels)
      # Number of responses
      N_resp <-  attributes(ModelForNames$terms)$response
      # All variables (dependent and independent)
      all_vars_init <- as.character(attributes(ModelForNames$terms)$variables)
      all_vars <- all_vars_init[2:length(all_vars_init)]
      # Retrieve predicted variables by using set difference
      dependent.vars <- setdiff(all_vars, independent.vars)
    }
  
  # Convert three dots into list
  extra.args <- list(...)
 
  # Serialize the model in order to upload it on Jaqpot
  model <- serialize(list(MODEL=trained.model, PREPROCESS = preprocess.model, ENSEMBLE = ensemble.model, 
                          extra.args = extra.args),connection=NULL)
  
  # Create a list containing the information that will be uploaded on Jaqpot
  tojson <- list(rawModel=model, runtime="R-caret", implementedWith="caret  R",
                 pmmlModel=NULL, independentFeatures=independent.vars,
                 predictedFeatures=dependent.vars, dependentFeatures=dependent.vars,
                 title=title, description=description, algorithm="Rcaret", additionalInfo = list(ymax = ymax, ymin = ymin, 
                                                                                                 ymean = ymean, ystd = ystd,
                                                                                                 ensemble.vars = ensemble.vars,
                                                                                                 replace = replace))
  # Convert the list to a JSON data format
  tryCatch({
    json <- jsonlite::toJSON(tojson)
  }, error = function(e) {
    e$message <-"Failed to convert trained.model to json. "
    stop(e)
  })
  
  # Check object size
  if(object.size(json) > 16000000 ){
    stop(" The model(s) you are trying to upload exceed the maximum size that the system can currently support")
  }
  # Function that posts the model on Jaqpot
  .PostOnService(base.path, token, json)
}
