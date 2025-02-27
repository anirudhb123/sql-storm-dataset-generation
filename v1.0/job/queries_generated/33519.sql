WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(X.ranking) AS average_rating
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    (SELECT 
        movie_id, 
        AVG(CASE WHEN info_type_id = 1 THEN CAST(info AS FLOAT) END) AS ranking
    FROM 
        movie_info
    GROUP BY movie_id) X ON X.movie_id = m.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    actor_name, movie_title, m.production_year, k.keyword
ORDER BY 
    production_year DESC, actor_name;
This SQL query does the following:

1. A recursive CTE named `MovieHierarchy` is created to form a hierarchy of movies and their sequels or related titles.
2. It selects actors from the `cast_info` table along with their movies, including production year and keywords.
3. It includes a left join to the `movie_keyword` table to get related keywords, handling cases where there are no keywords (using `COALESCE`).
4. It counts distinct production companies associated with the movie and calculates the average rating using a nested query based on the `movie_info` table.
5. Filters the results to include only movies produced between 2000 and 2023 while ensuring actor names are not null.
6. Finally, results are grouped by actor name, movie title, production year, and keyword, and ordered by the production year in descending order and actor name.
