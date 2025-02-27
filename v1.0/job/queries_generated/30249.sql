WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_movie_year,
    STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    MovieHierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    aka_title at ON m.movie_id = at.id
WHERE 
    ak.name IS NOT NULL 
    AND m.level = 0
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 10
ORDER BY 
    total_movies DESC;

WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)

SELECT 
    md.title,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    MovieDetails md
WHERE 
    md.keyword_count IS NOT NULL
ORDER BY 
    md.keyword_count DESC;
