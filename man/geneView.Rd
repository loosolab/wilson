% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/geneView.R
\name{geneView}
\alias{geneView}
\title{geneView's module server logic}
\usage{
geneView(
  input,
  output,
  session,
  clarion,
  plot.method = "static",
  label.sep = ", ",
  width = "auto",
  height = "auto",
  ppi = 72,
  scale = 1
)
}
\arguments{
\item{input}{Shiny's input object.}

\item{output}{Shiny's output object.}

\item{session}{Shiny's session object.}

\item{clarion}{A clarion object. See \code{\link[wilson]{Clarion}}. (Supports reactive)}

\item{plot.method}{Choose which method is used for plotting. Either "static" or "interactive" (Default = "static").}

\item{label.sep}{Separator used for label merging (Default = ", ").}

\item{width}{Width of the plot in cm. Defaults to minimal size for readable labels and supports reactive.}

\item{height}{Height of the plot in cm. Defaults to minimal size for readable labels and supports reactive.}

\item{ppi}{Pixel per inch. Defaults to 72 and supports reactive.}

\item{scale}{Scale plot size. Defaults to 1, supports reactive.}
}
\value{
Reactive containing data.table used for plotting.
}
\description{
Provides server logic for the geneView module.
}
\details{
Width/ height/ ppi less or equal to default will use default value.

Ppi less or equal to zero will use default.
}
