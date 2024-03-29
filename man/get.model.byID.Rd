% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_functions.R
\name{get.model.byID}
\alias{get.model.byID}
\title{Get the Information of a Jaqpot Model}
\usage{
get.model.byID(modelID, url = "https://api.jaqpot.org/jaqpot/")
}
\arguments{
\item{modelID}{A string containing the Jaqpot id of the model.}

\item{url}{The base path of Jaqpot services. This argument is optional and needs.
to be changed only if an alternative Jaqpot installation is used.}
}
\value{
All information relevant to the model.
}
\description{
The user can obtain the Information of a Jaqpot Model given the model id.
}
\details{
The user can obtain the information of a model that has been uploaded on Jaqpot by providing 
the appropriate model id. Note that that the user should also be the model creator.
}
\examples{
 \dontrun{
#model_info <- get.model.byID(modelID = "Lfz3aBdh4LlJIJxAvNqV")
}

}
