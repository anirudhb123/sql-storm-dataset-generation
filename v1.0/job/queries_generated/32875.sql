WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        0 AS level
    FROM title
    WHERE title.id IS NOT NULL

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link mt
    JOIN title t ON mt.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mt.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(*) OVER (PARTITION BY ak.name) AS num_movies,
    COALESCE(kw.keyword, 'No Keywords') AS keywords,
    ARRAY_AGG(DISTINCT cp.name) AS company_names,
    AVG(CASE WHEN mpi.info_type_id = 1 THEN mpi.info::int END) AS avg_rating
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN title m ON ci.movie_id = m.id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
LEFT JOIN movie_companies mc ON mc.movie_id = m.id
LEFT JOIN company_name cp ON mc.company_id = cp.id
LEFT JOIN movie_info mpi ON m.id = mpi.movie_id AND mpi.info_type_id = 1
WHERE m.production_year >= 2000
AND ak.name IS NOT NULL
AND ak.name NOT LIKE '%Unknown%'
GROUP BY ak.name, m.id, kw.keyword
HAVING COUNT(*) > 1
ORDER BY num_movies DESC, m.production_year DESC;
