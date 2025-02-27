WITH RECURSIVE RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        r.level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        RecursiveMovieHierarchy r ON ml.linked_movie_id = r.movie_id
    WHERE 
        r.level < 5  -- Limit to a recursive depth of 5
)
SELECT 
    DISTINCT ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mp.info AS INTEGER) ELSE 0 END) AS total_budget,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mp ON at.id = mp.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    RecursiveMovieHierarchy r ON at.id = r.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year > 2000
    AND (mp.info_type_id IS NULL OR mp.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Budget')))
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
    AND SUM(CASE WHEN mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN CAST(mp.info AS INTEGER) ELSE 0 END) > 1000000
ORDER BY 
    movie_title ASC, actor_name ASC;
