% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/login.R
\name{login.api}
\alias{login.api}
\title{Jaqpot login using api key with masking}
\usage{
login.api(url = "https://api.jaqpot.org/jaqpot/")
}
\arguments{
\item{url}{The base path of Jaqpot services. This argument is optional and needs 
to be changed only if an alternative Jaqpot installation is used.}
}
\value{
The function invisibly returns the jaqpot token, which is also written in the global environment
so that it can be used by other jaqpotr functions.
}
\description{
Provides the user the ability to communicate with the jaqpot server
}
\details{
The user  generates a 
token that is used by jaqpotr functions by providing the jaqpot api key. The difference of this
function with the function `login.api` is that it receives the user input with masking.
}
\examples{
 \dontrun{
login.api()
}

}
