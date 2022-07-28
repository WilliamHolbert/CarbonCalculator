library(forecast)
library(biwavelet)

arimas_monte <- function(models, n, n.iter) {
  # run dummy simulation and wavelet analysis to get number of periods for wavelet transform
  temp.sim.warm <- arimas_simulate(models=models, n=n)
  temp.wt <- wavelet_analysis(temp.sim.warm$sum,
                              years=seq(2000, length.out=length(temp.sim.warm$sum)),
                              sig.level=0.90, noise.type='white')
  
  sim.x <- array(NA, c(n, n.iter))
  sim.gws <- array(NA, c(length(temp.wt$gws), n.iter))
  for (i in 1:n.iter) {
    i.sim.warm <- arimas_simulate(models=models, n=n)
    i.wt <- wavelet_analysis(i.sim.warm$sum,
                             years=seq(2000, length.out=length(i.sim.warm$sum)),
                             sig.level=0.90, noise.type='white')
    sim.x[,i] <- i.sim.warm$sum
    sim.gws[,i] <- i.wt$gws
  }
  
  sim.x.stat <- cbind(MEAN=rowMeans(sim.x),
                      Q025=apply(sim.x, 1, quantile, 0.025),
                      Q975=apply(sim.x, 1, quantile, 0.975))
  
  sim.gws.stat <- cbind(MEAN=rowMeans(sim.gws),
                        Q025=apply(sim.gws, 1, quantile, 0.025),
                        Q975=apply(sim.gws, 1, quantile, 0.975))
  
  return(list(x=sim.x, gws=sim.gws, x.stat=sim.x.stat, gws.stat=sim.gws.stat))
}

arimas_simulate <- function(models, n, return_components=TRUE) {
  # run simulation on each model and combine into 2-d array
  sim.components <- lapply(models, arima_simulate, n=n)
  sim.components <- sapply(sim.components, cbind)
  
  # compute sum of individual component simulations
  if (ncol(sim.components) > 1) {
    sim.sum <- apply(sim.components, 1, FUN=sum)
  } else {
    sim.sum <- sim.components
  }
  
  if (return_components) {
    return(list(components=sim.components, sum=sim.sum))
  } else {
    return(sim.sum)
  }
}

arima_simulate <- function(model, n) {
  sim <- arima.sim(n=n,
                   list(ar=coef(model)[grepl('ar', names(coef(model)))],
                        ma=coef(model)[grepl('ma', names(coef(model)))]),
                   sd = sqrt(model$sigma2[[1]]))
  
  # extract intercept
  if ('intercept' %in% names(model$coef)) {
    intercept <- model$coef['intercept']
  } else {
    intercept <- 0
  }
  
  # add intercept (mean) to current simulation
  sim <- sim + intercept
  
  return(zoo::coredata(sim))
}

wavelet_analysis <- function(x, years, sig.level=0.90, noise.type=c("white", "red")) {
  noise.type <- match.arg(noise.type)
  lag1 <- switch(noise.type,
                 white = 0,
                 red = 0.72)
  
  bw <- biwavelet::wt(d=cbind(1:length(x), x), dt=1, dj=1/4, max.scale=length(x),
                      lag1=lag1, sig.level=sig.level, sig.test=0)
  
  # time-averaged global wave spectrum
  bw$gws <- apply(bw$power, 1, mean)
  bw$gws.sig <- biwavelet::wt.sig(d=cbind(x, years), dt=bw$dt, scale=bw$scale, sig.test=1,
                                  sig.level=sig.level, dof=length(x)-bw$scale,
                                  mother='morlet', lag1=lag1)
  
  return(bw)
}

sim_annual_arima <- function(x, start_year=2015, n_year=10) {
  stopifnot(all(!is.na(x)))
  
  # fit ARIMA model
  ar_model <- forecast::auto.arima(x, max.p=2, max.q=2, max.P=0, max.Q=0, stationary=TRUE)
  
  # simulation ARIMA model
  sim_x <- arima_simulate(model=ar_model, n=n_year)
  
  # create output zoo object
  sim_years <- seq(start_year, by = 1, length.out = n_year)
  out <- zoo::zoo(x = sim_x, order.by = sim_years)
  
  # return list
  list(model=ar_model,
       x=x,
       out=out)
}

plot_arimas_monte <- function(obs, wgen_mc) {
  wgen_stats <- data.frame(MEAN=colMeans(wgen_mc$x),
                           SD=apply(wgen_mc$x, 2, sd),
                           SKEW=apply(wgen_mc$x, 2, skewness))
  wgen_stats <- dplyr::mutate(wgen_stats, TRIAL=seq(1:n()))
  wgen_stats <- tidyr::gather(wgen_stats, STAT, VALUE, MEAN:SKEW)
  
  hist_stats <- data.frame(STAT=c('MEAN', 'SD', 'SKEW'),
                           VALUE=c(mean(obs), sd(obs), skewness(obs)))
  
  p <- ggplot2::ggplot(wgen_stats, aes(x=STAT, y=VALUE)) +
    ggplot2::geom_boxplot(fill='grey90') +
    ggplot2::stat_summary(fun.y=mean, geom='point', color='black', size=4) +
    ggplot2::geom_point(data=hist_stats, color='red', size=4) +
    ggplot2::facet_wrap(~STAT, ncol=3, scales='free') +
    ggplot2::labs(y='') +
    ggplot2::theme_bw() +
    ggplot2::theme(axis.ticks.x=ggplot2::element_blank(),
                   axis.title.x=ggplot2::element_blank(),
                   axis.text.x=ggplot2::element_blank())
  p
}
