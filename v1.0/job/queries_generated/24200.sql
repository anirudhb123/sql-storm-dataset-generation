WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(cast_p.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ca.nr_order) AS actor_order
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info AS ca ON m.id = ca.movie_id
    LEFT JOIN 
        aka_name AS cast_p ON ca.person_id = cast_p.person_id
    WHERE 
        m.production_year IS NOT NULL
        AND mk.keyword IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        mh.keyword,
        mh.actor_name,
        mh.actor_order
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS mv ON ml.linked_movie_id = mv.id
    WHERE 
        mh.movie_id <> mv.id
)

SELECT 
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT mh.keyword, ', ') AS all_keywords,
    COALESCE(
        STRING_AGG(DISTINCT CASE 
            WHEN mh.actor_order IS NOT NULL 
            THEN mh.actor_name 
            END, ', '), 
        'No Actors') AS actors_list,
    COUNT(DISTINCT mh.actor_name) AS total_actors,
    COUNT(DISTINCT mh.keyword) FILTER (WHERE mh.keyword LIKE 'Sci-Fi%') AS sci_fi_keywords,
    SUM(CASE 
        WHEN mh.actor_name IS NOT NULL THEN 1 
        ELSE 0 
    END) * 0.5 AS estimated_actor_weight
FROM 
    movie_hierarchy AS mh
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mh.actor_name) > 1
ORDER BY 
    estimated_actor_weight DESC,
    mh.production_year ASC
LIMIT 50;

-- Below is a subquery that fetches movies with no associated actors
SELECT 
    title,
    production_year 
FROM 
    aka_title 
WHERE 
    id NOT IN (SELECT DISTINCT movie_id FROM cast_info)
ORDER BY 
    production_year DESC
LIMIT 10;

### Explanation:
1. **CTE (Common Table Expression)**: This query uses a recursive CTE called `movie_hierarchy` to traverse through movies and their associated keywords and cast members.
2. **LEFT JOINs**: The outer joins help to fetch movies even if they have no associated keywords, and they are joined with the `cast_info` and `aka_name` tables to map actors.
3. **ROW_NUMBER()**: This window function partitions the results by movie and orders actors based on their appearance in the associated movie.
4. **STRING_AGG**: Aggregates keywords and actor names into a single string with a delimiter, handling cases where there might be NULLs.
5. **HAVING Clause**: Ensures that only films with more than one distinct actor are included in the final output.
6. **NULL Logic/Cases**: Handles scenario to show 'No Keywords' or 'No Actors' efficiently.
7. **Subquery for Films without Actors**: An additional subquery shows how to identify movies that do not have any associated actors, demonstrating the ability to handle OR logic and empty datasets.
8. **ORDER BY and LIMIT**: Controls the output ordering and limits the number of returned rows, enhancing efficiency for benchmark tasks.

This complex query is designed to serve dual purposes: performance benchmarking while also exploring the complex relationships within the dataset.
