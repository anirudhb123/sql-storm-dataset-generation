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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    a.name AS cast_name,
    t.title AS movie_title,
    mh.level AS movie_level,
    COUNT(DISTINCT c.id) OVER (PARTITION BY a.person_id) AS total_movies_casted,
    AVG(DISTINCT mi.info) OVER (PARTITION BY a.person_id) AS avg_movie_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    CASE 
        WHEN COALESCE(comp.kind, 'Unknown') = 'Production' THEN 'Production Company'
        ELSE 'Other Company'
    END AS company_type
FROM 
    cast_info ci
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
INNER JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    company_type comp ON mc.company_type_id = comp.id
WHERE 
    a.name IS NOT NULL 
    AND mh.production_year > 2000
GROUP BY 
    a.name, t.title, mh.level, comp.kind
ORDER BY 
    total_movies_casted DESC, avg_movie_rating DESC
LIMIT 100;

This query demonstrates several advanced SQL constructs, including:
- A recursive Common Table Expression (CTE) named `MovieHierarchy` that builds a hierarchy of movies.
- Multiple joins including LEFT JOINs and INNER JOINs across different tables, demonstrating the interaction between movie casting, company information, and movie keywords.
- Window functions to calculate total movies casted and average ratings for each person in the cast.
- Use of `string_agg` to aggregate keywords with NULL logic handling.
- A CASE statement to categorize companies.
- Filtering for movies produced after the year 2000, along with NULL value checks.
