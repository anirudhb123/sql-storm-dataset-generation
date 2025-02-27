WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.person_id,
        ta.title,
        ta.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ta.production_year DESC) AS rank
    FROM 
        cast_info ca
    INNER JOIN 
        aka_title ta ON ca.movie_id = ta.id
)

SELECT 
    ak.name AS actor_name,
    COALESCE(string_agg(DISTINCT am.title, ', '), 'No Movies') AS movies,
    COUNT(DISTINCT am.production_year) AS total_years_active,
    MAX(am.production_year) AS last_movie_year,
    CASE 
        WHEN COUNT(DISTINCT am.production_year) > 5 THEN 'Veteran Actor'
        WHEN COUNT(DISTINCT am.production_year) BETWEEN 2 AND 5 THEN 'Intermediate Actor'
        ELSE 'Newcomer'
    END AS actor_experience_level
FROM 
    aka_name ak
LEFT JOIN 
    ActorMovies am ON ak.person_id = am.person_id AND am.rank <= 10
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT am.title) > 0
ORDER BY 
    actor_experience_level DESC, 
    COUNT(DISTINCT am.title) DESC;

This query achieves the following:

1. It starts with a recursive Common Table Expression (CTE) named `ActorMovies` which retrieves each actor's titles and production years from the `cast_info` and `aka_title` tables, ranking their movies by production year.

2. The main query selects distinct actor names from the `aka_name` table, joining with the `ActorMovies` CTE based on `person_id` and limiting to the latest 10 movies for each actor.

3. It uses the `COALESCE` function to concatenate movie titles or provide a default message if no movies are found.

4. The `COUNT` and `MAX` functions are employed to compute the total years active and the year of the last movie, respectively.

5. A `CASE` statement categorizes the actors based on their level of experience determined by the number of distinct production years.

6. The query groups results by actor name, filters to ensure only actors with at least one movie are included, and sorts the final output by experience level and total titles.
