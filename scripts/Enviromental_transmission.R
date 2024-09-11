# Network transmission simulator (SIR model): An usage map is generated and used to link focal reservoirs
NIDs=100
Steps=365
Nrep=10   # Number of replicates

beta=0.0001 # Transition rate from S to I (Infection rate): Linked to number of infected spots
#theta=0.0  # Transmission rate from S to E * not included
mu  =0.10 # Transition rate from I to R
gamma=0.10 # Transition rate from R to S

map_scale_x=100
map_scale_y=100
nspots=3 # Number of reservoirs
reservoirs=matrix(0,nrow=map_scale_y,ncol=map_scale_x)
reservoirs[cbind(sample(1:map_scale_y,nspots),sample(1:map_scale_x,nspots))]=1
gamma_shape=0.25 # Area utilization time distributions
gamma_scale=40
#hist(rgamma(100,shape = gamma_shape, scale = gamma_scale))
  # In a full infected area= 1, each minute will increase one % the total risk of infection beta*(1+(time*infection))

Infected=c(5,30,50)
Status=matrix(0,nrow=NIDs,ncol=Steps)
# being 0=Susceptible; 1=Infectious; 2=Recovered
area_list=list()

#Add infected individuals
Status[Infected,1]=1

Status_rep=data.frame();Status_list=list()
for (r in 1:Nrep){
  # Simulate infection based on daily networks
  for (step in 2:Steps){
    # Simulate one random network per day
    area=list()

    # Dynamic reservoirs
    #reservoirs=matrix(0,nrow=map_scale_y,ncol=map_scale_x)
    #reservoirs[cbind(sample(1:map_scale_y,nspots),sample(1:map_scale_x,nspots))]=1

    for (i in 1:NIDs){
      area[[i]]=matrix(rgamma(map_scale_x*map_scale_y,
                              shape = gamma_shape, scale = gamma_scale),
                       nrow=map_scale_y,ncol=map_scale_x)
      # Time spent in area ~ max 400
    }
    area_list[[step]]=area
    # Transition rate from R to S
    RInf=which(Status[,(step-1)]==2)
    if(length(RInf)>0){
      IInf=rbinom(length(RInf), size = 1, prob=(1-gamma)) #prob of continue recovered
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

    # Transmission from environment
    NonInfIDs=which(Status[,step]==0)
    if (length(NonInfIDs)>0){
      for (id in NonInfIDs){
        #newbeta=beta*(1+(time*infection))
        beta_prob=sum(beta*(1+(area[[i]][which(reservoirs>0)]*reservoirs[which(reservoirs>0)]/100)))
        EnvInf   =rbinom(nspots, size = 1, prob=beta_prob) #Individuals with risk of infection
        if(sum(EnvInf==1)>0)  Status[id,step]=1
        rbinom(length(beta_prob), size = 1, prob=beta_prob)==1
        rm(beta_prob)
      }
      rm(RInf,IInf,InfIDs,area)
    }
  }
  Status_list[[r]]=Status

  Status_rep_tmp=cbind(rep(r,Steps),1:Steps,colSums(Status==0),colSums(Status==1),colSums(Status==2))
  colnames(Status_rep_tmp)=c("Replicate","Step","Susceptible","Infected","Recovered")
  Status_rep=rbind(Status_rep,Status_rep_tmp)
}

# infection graphs
# Infected animals
plot(colSums(Status==0),type="l", col="darkgreen",ylim = c(0,NIDs),
     main="Enviromental pathogen transmission", ylab="Proportion of individuals", xlab="Days")
# Recover animals
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
         main="Environmental pathogen transmission", ylab="Proportion of individuals", xlab="Days")
  }else{
    lines(Status_rep_avg[,i+1], col=col[i])
  }
  x=c(Status_rep_sd[,1], rev(Status_rep_sd[,1]  ))
  y=c(Status_rep_avg[,i+1]-Status_rep_sd[,i+1], rev(Status_rep_avg[,i+1]+Status_rep_sd[,i+1]))
  polygon(x, y, col = adjustcolor(col[i], alpha.f = 0.1), border = NA)
  rm(x,y)
}
legend( x="topleft",
        legend=c("Susceptible","Infected","Recovered"),
        col=c("darkgreen","orange","blue"), lty=1)


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




