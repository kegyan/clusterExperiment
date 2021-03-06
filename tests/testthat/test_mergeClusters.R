context("mergeClusters")


test_that("`mergeClusters` works with matrix and ClusterExperiment objects", {
  cl1 <- clusterSingle(smSimData, 
                       subsample=FALSE, sequential=FALSE,
                       mainClusterArgs=list(clusterFunction="pam",clusterArgs=list(k=6)),isCount=FALSE)
  leg<-clusterLegend(cl1)[[primaryClusterIndex(cl1)]]
  leg[,"name"]<-letters[1:6]
  clusterLegend(cl1)[[primaryClusterIndex(cl1)]]<-leg
  clustWithDendro <- makeDendrogram(cl1)
  #matrix version
  mergedList <- mergeClusters(x=transformData(cl1), isCount=FALSE,
                              cl=primaryCluster(cl1),
                              dendro=clustWithDendro@dendro_clusters,
                              mergeMethod="adjP", plotInfo="mergeMethod")
  
	#check plotting types:
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none",plotInfo="all")
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none", plotInfo="adjP")
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none", plotInfo="locfdr")
  expect_warning(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none", plotInfo="locfdr",showWarnings=TRUE))
  expect_error(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none", plotInfo="mergeMethod"),"can only plot 'mergeMethod' results if one method is selected")
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="none")

  #check all methods run
  for(method in clusterExperiment:::.availMergeMethods){
	  clustMerged <- mergeClusters(clustWithDendro, mergeMethod=method, plotInfo="mergeMethod")
  }
  
  expect_true("mergeClusters" %in% clusterTypes(clustMerged))
  expect_true("mergeClusters" %in% colnames(clusterMatrix(clustMerged)))

	clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="samples",plotType="colorblock")
	clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="samples",plotType="name")
	clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="clusters",plotType="colorblock")
	clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="clusters",plotType="name")

  expect_error(mergeClusters(x=transformData(clustWithDendro), isCount=FALSE,
                               cl=primaryCluster(clustWithDendro),plot="none",
                               mergeMethod="adjP",
                               dendro=clustWithDendro@dendro_samples),
                 "Not a valid input dendrogram")

  #test if already exists
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP")
  primaryClusterIndex(clustMerged)<-2
  clustMerged<- makeDendrogram(clustMerged)
  clustMerged2<-mergeClusters(clustMerged,mergeMethod="adjP")
  expect_true("mergeClusters.1" %in% clusterTypes(clustMerged2))
  expect_true(!"combineMany.1" %in% clusterTypes(clustMerged2))
  expect_true(!"clusterMany.1" %in% clusterTypes(clustMerged2))
  removeClusterings(clustMerged, whichClusters = "mergeClusters")
})


test_that("saving merge info works",{
  expect_silent(cl1 <- clusterSingle(smSimData, 
       subsample=FALSE, sequential=FALSE, reduceMethod="none",
	   mainClusterArgs=list(clusterFunction="pam",clusterArgs=list(k=6)),
	   isCount=FALSE))
	   #check cluster is same, otherwise won't get same results...
  expect_equal(primaryCluster(cl1),c(1,2,2,3,2,4,3,2,2,5,5,5,6,6,1,4,4,4))
  #for some reason, clusterSingle not giving reasonable names
  test<-clusterLegend(cl1)[[1]]
  test[,"name"]<-test[,"clusterIds"]
  clusterLegend(cl1)[[1]]<-test
  expect_silent(clustWithDendro <- makeDendrogram(cl1,reduceMethod="none"))
  #Old dendrogram:
  # > str(clustWithDendro@dendro_clusters)
  # --[dendrogram w/ 2 branches and 6 members at h = 1509]
  #   |--leaf "5"
  #   `--[dendrogram w/ 2 branches and 5 members at h = 1455]
  #      |--[dendrogram w/ 2 branches and 2 members at h = 228]
  #      |  |--leaf "2"
  #      |  `--leaf "3"
  #      `--[dendrogram w/ 2 branches and 3 members at h = 337]
  #         |--leaf "6"
  #         `--[dendrogram w/ 2 branches and 2 members at h = 259]
  #            |--leaf "1"
  #            `--leaf "4"
  #matrix version
  expect_silent(mergedList <- mergeClusters(x=transformData(cl1), isCount=FALSE,
                              cl=primaryCluster(cl1),
                              dendro=clustWithDendro@dendro_clusters,
                              mergeMethod="adjP", plotInfo="none"))
  
  ##check giving nodePropTable
  expect_silent(mergedList2<- mergeClusters(x=transformData(cl1), isCount=FALSE,
                              cl=primaryCluster(cl1), nodePropTable=mergedList$propDE,
                              dendro=clustWithDendro@dendro_clusters,
                              mergeMethod="Storey", plotInfo="none"))
  expect_equal(mergedList2$propDE[,"adjP"],mergedList$propDE[,"adjP"])
  expect_silent(mergedListStorey<-mergeClusters(x=transformData(cl1), isCount=FALSE,
                                  cl=primaryCluster(cl1), 
                                  dendro=clustWithDendro@dendro_clusters,
                                  mergeMethod="Storey", plotInfo="mergeMethod"))
  expect_equal(mergedList2$propDE[,"Storey"],mergedListStorey$propDE[,"Storey"])  
  expect_silent(mergedList2Redo<- mergeClusters(x=transformData(cl1), isCount=FALSE,
                              cl=primaryCluster(cl1), nodePropTable=mergedList2$propDE,
                              dendro=clustWithDendro@dendro_clusters,
                              mergeMethod="none", plotInfo=c("all")))
  
  #on ClusterExperiment
  expect_message(clustMerged <- mergeClusters(clustWithDendro,
	   mergeMethod="adjP",plotInfo="none",plot=FALSE,calculateAll=FALSE))
  expect_equal(clustMerged@merge_dendrocluster_index,clustWithDendro@dendro_index+1)
  expect_equal(clustMerged@merge_dendrocluster_index,clustMerged@dendro_index)
  expect_equal(clustMerged@merge_index,1)
  #add to existing with different method
  expect_message(clustMerged2 <- mergeClusters(clustMerged, mergeMethod="Storey",
  	plotInfo="none",cutoff=0.1,plot=FALSE,calculateAll=FALSE))
  expect_equal(clustMerged2@merge_dendrocluster_index,clustMerged@dendro_index+1)
  expect_equal(clustMerged2@merge_dendrocluster_index,clustMerged2@dendro_index)
  expect_equal(clustMerged2@merge_index,1)
  #rerun previous with different cutoff -- no new calculations
  expect_message(clustMerged3 <- mergeClusters(clustMerged2, mergeMethod="Storey",
  	plotInfo="none",cutoff=0.05,plot=FALSE,calculateAll=FALSE))
  expect_equal(clustMerged3@merge_dendrocluster_index,clustMerged2@dendro_index+1)
  expect_equal(clustMerged3@merge_dendrocluster_index,clustMerged3@dendro_index)
  expect_equal(clustMerged3@merge_index,1)
  expect_message(clustMerged4 <- mergeClusters(clustMerged3, mergeMethod="Storey",
  	plotInfo="none",cutoff=0.5,plot=FALSE,calculateAll=FALSE))
  expect_equal(clustMerged4@merge_dendrocluster_index,clustMerged3@dendro_index+1)
  expect_equal(clustMerged4@merge_dendrocluster_index,clustMerged4@dendro_index)
  expect_equal(clustMerged4@merge_index,1)
  expect_equal(clustMerged4@merge_nodeMerge[,"mergeClusterId"],c(NA,NA,2,1,NA))
  expect_equal(clustMerged4@merge_nodeMerge[,"isMerged"],c(FALSE,FALSE,TRUE,TRUE,TRUE))
  #check really gets clusterIds and not names
  expect_silent(clusterLegend(clustMerged3)[["clusterSingle"]][,"name"]<-letters[1:6])
  expect_message(clustMerged5 <- mergeClusters(clustMerged3, mergeMethod="Storey",
  	plotInfo="none",cutoff=0.5,plot=FALSE,calculateAll=FALSE))
  expect_equal(clustMerged4@merge_nodeMerge,clustMerged5@merge_nodeMerge)
  #helpful for debugging:
  # plotDendrogram(clustMerged,show.node=TRUE,show.tip.label=TRUE)
  # table(clusterMatrix(clustMerged)[,c(1)],clusterMatrix(clustMerged)[,c(2)])
  
  expect_silent(nodeMergeInfo(clustMerged4))
  expect_equal(mergeClusterIndex(clustMerged4),clustMerged4@merge_index)
  expect_equal(mergeCutoff(clustMerged4),0.5)
  expect_equal(mergeMethod(clustMerged4),"Storey")
  
  #check if can calculate all, but do nothing else
  expect_message(clustMergedAll<-mergeClusters(clustWithDendro, mergeMethod="none",plotInfo="none",cutoff=0.5,plot=FALSE,calculateAll=TRUE))
  expect_false(is.na(clustMergedAll@merge_dendrocluster_index))
  expect_true(is.na(clustMergedAll@merge_index))
  expect_false(is.null(nodeMergeInfo(clustMergedAll)))
  
  #should erase merge info if call dendrogram
  expect_silent(clustMergedErase<-makeDendrogram(clustMerged5))
  expect_true(is.na(clustMergedErase@merge_index))
  expect_true(is.na(clustMergedErase@merge_dendrocluster_index))
  
  #should erase merge info if call dendrogram
  expect_silent(clustMergedErase2<-makeDendrogram(clustMergedAll))
  expect_true(is.na(clustMergedErase2@merge_index))
  expect_true(is.na(clustMergedErase2@merge_dendrocluster_index))

  #test getMergeCorresp
  #node clustMerge
  mgCl<-clusterMatrix(clustMerged)[,clustMerged@merge_index]
  ogCl<-clusterMatrix(clustMerged)[,clustMerged@merge_dendrocluster_index]
  expect_silent(mc<-getMergeCorrespond(clustMerged))
  expect_equal(length(mc),length(unique(mgCl[mgCl>0])))
  expect_silent(mc<-getMergeCorrespond(clustMerged,by="original"))
  expect_equal(length(mc),length(unique(ogCl[ogCl>0])))
  
  expect_error(getMergeCorrespond(clustMergedAll),"there is no merge clustering in this object")
  #check saves even if just plotInfo
  clustMerged <- mergeClusters(clustWithDendro, mergeMethod="none",plotInfo="all")
  expect_false(is.null(clustMerged@merge_nodeProp))
})
test_that("`mergeClusters` preserves the colData and rowData of SE", {

  expect_silent(cl <- clusterSingle(smSimSE, 
       subsample=FALSE, sequential=FALSE,                      
	   mainClusterArgs=list(clusterFunction="pam",clusterArgs=list(k=6)),
	   isCount=FALSE))
  expect_silent(clD <- makeDendrogram(cl))
  expect_message(cl <- mergeClusters(clD, mergeMethod = "adjP"))
  expect_equal(colData(cl),colData(smSimSE))
  expect_equal(rownames(cl),rownames(smSimSE))
  expect_equal(colnames(cl),colnames(smSimSE))
  expect_equal(metadata(cl),metadata(smSimSE))
  expect_equal(rowData(cl),rowData(clD))

})


test_that("`mergeClusters` works with unassignedSamples", {

  expect_silent(clustWithDendro <- makeDendrogram(ceSim,unassignedSamples = c("outgroup")))

	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP",
		 plotInfo="mergeMethod",leafType="samples",plotType="colorblock"))
	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP",
		 plotInfo="mergeMethod",leafType="samples",plotType="name"))
	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP",
		 plotInfo="mergeMethod",leafType="clusters",plotType="colorblock"))
	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="clusters",plotType="name"))

  expect_silent(clustWithDendro <- makeDendrogram(ceSim,reduceMethod="mad",unassignedSamples = c("cluster")))

	expect_warning(mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="samples",plotType="colorblock"),"You cannot set 'leafType' to 'samples' in plotting mergeClusters unless the dendrogram was made with unassigned/missing")
	expect_warning(mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="samples",plotType="name"),"You cannot set 'leafType' to 'samples' in plotting mergeClusters unless the dendrogram was made with unassigned/missing")
	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="clusters",plotType="colorblock","You cannot set 'leafType' to 'samples' in plotting mergeClusters unless the dendrogram was made with unassigned/missing"))
	expect_message(clustMerged <- mergeClusters(clustWithDendro, mergeMethod="adjP", plotInfo="mergeMethod",leafType="clusters",plotType="name","You cannot set 'leafType' to 'samples' in plotting mergeClusters unless the dendrogram was made with unassigned/missing"))


})

