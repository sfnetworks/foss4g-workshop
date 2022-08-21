# Challenges

Time for a hands-on round! Below you will find a set of challenges, ranging from beginners to advanced level that will allow you to use what you just learnt about `sfnetworks` and spatial network analysis. 

We want to see your work! Exploring how the community uses the package is one of the best ways we have to discover bugs, point us to new features or to get amazed by the possibilities of the package. 

To share your solution to your chosen challenge, you can create a pull-request on this repository following this [template.Rmd](https://github.com/sfnetworks/foss4g-workshop/tree/main/challenges/template.Rmd) file. You can call your file `challengecode_name.Rmd`, e.g. `ch0102_Lorena.Rmd` and save into the [challenges](https://github.com/sfnetworks/foss4g-workshop/tree/main/challenges) directory.

## Beginners :fire:

This is the first time you are working with R-Spatial and related packages? Give these challenges a go. 

You can start by trying to get road network data from Florence yourself, as shown on the demo. But if that is too much, you can take a look into the [data/](https://github.com/sfnetworks/foss4g-workshop/tree/main/data/) directory, where some data is already prepared for you. The same goes for the POIs. If you want to do this yourself, you can check the [scripts/](https://github.com/sfnetworks/foss4g-workshop/tree/main/scripts/) directory, which might even have some extra helper scripts for you :smile:

- `ch0101`: It is September 8th, 1504. Michelangelo is waking up at his residence, later known as Casa Buonarroti. Today he needs to go to Palazzo Vecchio to finally unveil his masterpiece sculpture: **David**. What would be the fastest way for him to get there? *Bonus:* He forgot he should pass the Duomo first before the unveil, how would his route change?

- `ch0102`: April 17th, 1480. Leonardo da Vinci is, as usual, at the Medici Palace. He feels like going for a walk of around 20 minutes. Which areas in Florence can he reach within this time?

- `ch0103`: In 1475, the official library of the Medici Palace flared up and, unfortunately, all street maps stored in the building were destroyed during the accident. Lorenzo di Piero de' Medici, the ruler of the city, asks the local geographers to recreate those maps and you need to help them! Pick your favourite city, download the street network data from OSM, and replicate some of the steps presented during the demo. Complete the analysis creating a beautiful map of the city network.  

## Intermediate :fire: :fire:

If you have a bit more experience with coding in general, these challenges might be more for your taste. 

For acquiring the needed data, please read the **Beginners** prompt.

- `ch0201`: It's Wednesday, the first day of the conference is about to finish. The last talk you want to attend ends at 4PM. You have some time to kill before the ice-breaker at 6PM, why not do a little tour of Florence attractions? Under [data/pois.rda](https://github.com/sfnetworks/foss4g-workshop/tree/main/data/) you will find a set of points of interest in the city. How many can you visit within these two hours? What is the final route you will take?

- `ch0202`: The R package [`tidygraph`]((https://tidygraph.data-imaginist.com/reference/index.html)) implements several algorithms for network analysis (e.g. centrality calculation or community detection). Considering the street network of your favourite city (or a toy example), try to cluster the nodes using the *simulated annealing* algorithm and compute the *weighted* edge betweenness centrality measure (the weights are the spatial lengths of the segments). Represent the results. 

- `ch0203`:

## Advanced :fire: :fire: :fire

Are you also a package developer? Do you happen to be a graph analysis expert? Is R-Spatial your daily work? Here are a couple of open issues from `sfnetworks` we would love to discuss (and possibly solve!) with our community. 

If you choose any of these, feel free to either fill in the template and PR to this repo, or comment on the issue itself and PR to the `sfnetworks` repo.

- `ch0301`: [Standard creation functions for spatial graphs from only points](https://github.com/luukvdmeer/sfnetworks/issues/52)

- `ch0302`: [Function for map matching of trajectories](https://github.com/luukvdmeer/sfnetworks/issues/114)

- `ch0303`: [Morpher to snap edges that are close to each other](https://github.com/luukvdmeer/sfnetworks/issues/115)

- `ch0304`: [Enable edge subdivision at every edge crossing](https://github.com/luukvdmeer/sfnetworks/issues/134)

- `ch0305`: [K-shortest path](https://github.com/luukvdmeer/sfnetworks/issues/142)

