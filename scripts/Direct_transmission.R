# Required packages
library(dplyr)

# Network transmission simulator (SIR model)
NIDs=100
Steps=365
beta=0.005 # Transition rate from S to I (Infection rate)
mu  =0.10 # Transition rate from I to R
teta=0.10 # Transition rate from R to S
mean_degree=20
Infected=c(5,30,50)
Nrep=10   # Number of replicates


Status_rep=data.frame();Status_list=list()
for (r in 1:Nrep){
  Status=matrix(0,nrow=NIDs,ncol=Steps)
  # being 0=Susceptible; 1=Infectious; 2=Recovered
  net_list=list()

  #Add infected individuals
  Status[Infected,1]=1

  # Simulate infection based on daily networks
  for (step in 2:Steps){
    # Simulate one random network per day
    net=matrix(0,nrow=NIDs,ncol=NIDs)
    for (i in 1:NIDs){
      net[i:NIDs,i] =rbinom((NIDs-(i-1)), size = 1, prob=mean_degree/NIDs)
      net[i,i:NIDs] = net[i:NIDs,i]
      diag(net)=0
        # being 0=non-contact; 1=contacted
      net_list[[step]]=net
    }

    # Transition rate from R to S
    RInf=which(Status[,(step-1)]==2)
    if(length(RInf)>0){
      IInf=rbinom(length(RInf), size = 1, prob=(1-teta)) #prob of continue recovered
      IInf[IInf==1]=2
      Status[RInf,step]=IInf
    }

    # Transition rate from I to R
    RInf=which(Status[,(step-1)]==1)
    if(length(RInf)>0){
      IInf=rbinom(length(RInf), size = 1, prob=(1-mu)) #prob of continue infected
      IInf[IInf==0]=2
      Status[RInf,step]=IInf
    }

    # Transmission between individuals
    InfIDs=sample(which(Status[,step]==1))
    if (length(InfIDs)>0){
      for (id in InfIDs){
        RInf=which(net[id,]==1) #Individuals with risk of infection
        if(length(RInf)>0){
          IInf=rbinom(length(RInf), size = 1, prob=beta) #infected IDs
          IInf=RInf[IInf==1]
          if(length(IInf)>0){
            for (id2 in IInf) Status[id2,step]=ifelse(Status[id2,(step-1)]==0,1,Status[id2,(step-1)])
          }
        }
      }
      rm(RInf,IInf,InfIDs)
    }
  }
  Status_list[[r]]=Status

  Status_rep_tmp=cbind(rep(r,Steps),1:Steps,colSums(Status==0),colSums(Status==1),colSums(Status==2))
  colnames(Status_rep_tmp)=c("Replicate","Step","Susceptible","Infected","Recovered")
  Status_rep=rbind(Status_rep,Status_rep_tmp)
}

# Infection graphs
# Health animals
plot(colSums(Status==0),type="l", col="darkgreen",ylim = c(0,NIDs),
     main="Direct pathogen transmission", ylab="Proportion of individuals", xlab="Days")
# Infected animals
lines(colSums(Status==1), col="orange")
# Recover animals
lines(colSums(Status==2),type="l", col="blue")




# Average infection graphs
Status_rep_avg=Status_rep %>%
  group_by(Step) %>%
  summarize(across(c(Susceptible,Infected,Recovered), mean))
Status_rep_avg=as.data.frame(Status_rep_avg)
Status_rep_sd=Status_rep %>%
  group_by(Step) %>%
  summarize(across(c(Susceptible,Infected,Recovered), sd))
Status_rep_sd=as.data.frame(Status_rep_sd)

col=c("darkgreen","orange","blue")
for (i in 1:3){
  if(i==1){
    plot(Status_rep_avg[,(i+1)],type="l", col=col[i], ylim = c(0,NIDs),
         main="Direct pathogen transmission", ylab="Proportion of individuals", xlab="Days")
  }else{
    lines(Status_rep_avg[,i+1], col=col[i])
  }
  x=c(Status_rep_sd[,1], rev(Status_rep_sd[,1]  ))
  y=c(Status_rep_avg[,i+1]-Status_rep_sd[,i+1], rev(Status_rep_avg[,i+1]+Status_rep_sd[,i+1]))
  polygon(x, y, col = adjustcolor(col[i], alpha.f = 0.1), border = NA)
  rm(x,y)
}



# Infection length
n0s=n1s=n2s=vector()
for(i in 1:nrow(Status)){
  infstats=rle(Status[i,])
  infstats1=infstats[[1]][1:(length(infstats[[1]])-1)]
  infstats2=infstats[[2]][1:(length(infstats[[2]])-1)]
  n0s=c(n0s,infstats1[infstats2==0])
  n1s=c(n1s,infstats1[infstats2==1])
  n2s=c(n2s,infstats1[infstats2==2])

  rm(infstats,infstats1,infstats2)
}

boxplot(n0s,n1s,n2s, ylim=c(0,Steps), col=c("darkgreen","orange","blue"))
#boxplot(n0s,col="darkgreen")
#boxplot(n1s,col="orange")
#boxplot(n2s,col="blue")


