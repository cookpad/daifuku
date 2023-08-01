# recipe_search

An category of events related to recipe search.

## search

An event sent when users perform a recipe search.

- keyword: !string 256
    - Search keyword
- order: SearchOrder
   - latest, popularity

## show_recipe

Sent when users move from the search results screen to the recipe details screen.

- recipe_id: !integer
    - ID of the selected recipe
