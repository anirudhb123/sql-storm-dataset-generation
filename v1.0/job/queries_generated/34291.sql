WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 'Unknown Year') AS production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    ct.kind AS character_type,
    COUNT(ci.id) OVER (PARTITION BY ak.id ORDER BY at.production_year) AS total_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(at.production_year) OVER (PARTITION BY ak.id) AS earliest_role_year,
    COALESCE(COUNT(DISTINCT mc.company_id), 0) AS production_companies
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%deleted%'
    AND at.production_year > 2000
GROUP BY 
    ak.id, at.id, ct.kind
ORDER BY 
    earliest_role_year DESC, total_movies DESC
LIMIT 50;

This SQL query performs the following tasks:

1. Uses a recursive Common Table Expression (CTE) to create a movie hierarchy that allows for up to three levels of linked movies.
2. Selects various fields from the `aka_name`, `aka_title`, `cast_info`, `comp_cast_type`, `movie_keyword`, `keyword`, and `movie_companies` tables.
3. Implements window functions to aggregate total movies per actor and to find the earliest role year.
4. Uses `STRING_AGG` to concatenate keywords associated with each movie.
5. Utilizes a left join to count distinct production companies for each movie.
6. Includes a complex WHERE clause to filter out invalid names and restrict the production year to movies released after 2000.
7. Orders the results by the earliest role year and total movies to highlight established actors.
8. Limits the output to the top 50 results for performance benchmarking.
