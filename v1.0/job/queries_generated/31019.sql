WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        title.title,
        title.production_year,
        1 AS depth
    FROM 
        aka_title title
    INNER JOIN 
        movie_companies mcomp ON title.id = mcomp.movie_id
    WHERE 
        title.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.linked_movie_id IS NOT NULL
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS overall_movie_count,
    COUNT(DISTINCT m.id) AS co_starring_movies,
    AVG(m.production_year) AS average_year_of_production,
    string_agg(DISTINCT mh.title, ', ') AS linked_movies,
    SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_movies,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank,
    (SELECT COUNT(*) FROM film_bib WHERE actor_id = ak.person_id) AS total_roles
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.person_id
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5 AND
    AVG(m.production_year) > 2000
ORDER BY 
    overall_movie_count DESC,
    rank ASC
LIMIT 10;
