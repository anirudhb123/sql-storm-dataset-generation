WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS title_rank
    FROM 
        aka_title t
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT t.title, ', ') AS titles_list,
    COALESCE(MAX((SELECT i.info FROM person_info i WHERE i.person_id = a.person_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Oscar'))), 'No Oscar Info') AS oscar_info
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    RankedTitles t ON c.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = t.title AND m.production_year = t.production_year)
WHERE 
    a.name IS NOT NULL 
    AND c.note IS NULL 
    AND t.title IS NOT NULL 
    AND c.nr_order = (
        SELECT MAX(nr_order) FROM cast_info ci WHERE ci.movie_id = c.movie_id
    )
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
    OR (COUNT(DISTINCT c.movie_id) <= 5 AND STRING_AGG(DISTINCT t.title, ', ') ILIKE '%Award%')
ORDER BY 
    movie_count DESC,
    actor_name ASC;

### Explanation
- **CTE (Common Table Expression)**: The `RankedTitles` CTE ranks titles by production year and title alphabetically.
- **LEFT JOIN**: Joins `aka_name`, `cast_info`, and the ranked titles, allowing for the inclusion of actors who might not have been in any movie.
- **SUBQUERY**: A correlated subquery in the `AVL` clause retrieves Oscar information, defaulting to 'No Oscar Info' if not found.
- **Aggregate Functions**: Uses `COUNT`, `AVG`, and `STRING_AGG` to provide a useful summary of each actor's involvement in movies.
- **Complex Predicate Logic**: The `WHERE` clause uses several conditions regarding `NULL` checks and `nr_order`.
- **HAVING Clause**: Filters records according to specific criteria related to movie counts and award mentions in titles.
- **Order By**: Results are sorted first by the number of movies acted and then alphabetically by the actor's name. 

This blend of features tests various SQL functionalities which can be important for performance benchmarking.
