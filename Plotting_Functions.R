

## Heatmap Colour Gradient Scale
library(RColorBrewer)
color_gradient_blue_red = rev(brewer.pal(n = 10, name = "RdYlBu"))


## Load Arial
library(extrafont)
font_import(paths = "data", pattern = "arial.ttf")
loadfonts()

## Size parameters
stroke = 0.3
size = 0.15
lines = 0.25

## Custom theme for panels with small text
theme_panel<- function(){
  font <- "Arial"   #assign font family up front

  theme_classic() %+replace%    #replace elements we want to change

    theme(

      #text elements
      plot.title = element_text(             #title
        family = font,            #set font family
        size = 7,                #set font size
        # face = 'bold',            #bold typeface
        hjust = 0),               #raise slightly

      axis.title = element_text(             #axis titles
        family = font,            #font family
        size = 7),               #font size

      axis.text = element_text(              #axis text
        family = font,            #axis famuly
        size = 6),                #font size

      legend.text = element_text(             #legend items
        family = font,            #font family
        size = 7),                #font size

      line = element_line(size=lines)
    )
}

## Single Cell Plotting Functions
library(Seurat)
library(ggplot2)
marker_plot_plot = function(m, seurat) {
  Embeddings(seurat, reduction = "umap") %>% as_tibble() %>%
    mutate(g = as.matrix(seurat@assays[[seurat@active.assay]][m,])[1,]) -> pdat

  ggplot() +
    geom_point(data = pdat[pdat$g<0,], aes(x=UMAP_1, y=UMAP_2), stroke=stroke, size=size, colour="lightgrey") +
    geom_point(data = pdat[pdat$g>=0,], aes(x=UMAP_1, y=UMAP_2, color=g),  stroke=stroke, size=size) +
    #    scale_color_gradientn(colours = rev(brewer.pal(n = 7, name =
    # "RdYlBu"))) +
    scale_color_gradientn(colours = c("lightgrey", rev(brewer.pal(n = 11, name =
                                                                    "Spectral")[1:5]))) +
    theme_panel() +
    theme(legend.position = "bottom", legend.key.height = unit(0.5,"line"),
          legend.spacing.x = unit(0.2, 'cm'),
          legend.box.margin = margin(t=-0.4, unit = "cm")) +
    labs(x="UMAP1", y="UMAP2", colour=m) -> p

  p
}

signature_scoring_plot_plot = function(sig, seurat) {
  Embeddings(seurat, reduction = "umap") %>% as_tibble() %>%
    mutate(s = seurat@meta.data[,sig]) %>%
    ggplot(., aes(UMAP_1, UMAP_2)) +
    geom_point(aes(colour=s), stroke=stroke, size=size) +
    scale_color_gradientn(colours = rev(brewer.pal(n = 10, name =
                                                     "RdYlBu"))) +
    theme_classic() +
    theme(legend.position = "bottom", legend.key.height = unit(0.5,"line"),
          legend.spacing.x = unit(0.2, 'cm'),
          line = element_line(size=lines),
          text = element_text(family = "Arial",size = 7),
          legend.box.margin = margin(t=-0.4, unit = "cm")) +
    labs(x="UMAP1", y="UMAP2", colour=sig) -> p
  p
}

## Arrange Multiple Plots in a grid, setting the panel size
library(gridExtra)
panel_it = function(plot_list, width = 2.5, height = 2.5, nrow=1) {
  grid.arrange(grobs = lapply(
    plot_list,
    set_panel_size,
    width = unit(width, "cm"),
    height = unit(height, "cm")
  ),nrow=nrow) -> p
  p
}

