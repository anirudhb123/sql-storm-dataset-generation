WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS full_title
    FROM 
        aka_title mt
    WHERE 
        mt.title IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.full_title || ' -> ' || at.title AS VARCHAR(255)) AS full_title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    am.title AS movie_title,
    COALESCE(years.series_years::text, 'N/A') AS series_years,
    COUNT(DISTINCT mh.movie_id) AS total_related_movies,
    STRING_AGG(DISTINCT mh.full_title, ', ') AS related_movies,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS ranking
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title am ON ci.movie_id = am.id
LEFT JOIN 
    movie_keyword mk ON am.id = mk.movie_id
LEFT JOIN 
    movie_hierarchy mh ON am.id = mh.movie_id
LEFT JOIN 
    title years ON am.id = years.id AND (years.season_nr IS NOT NULL OR years.episode_nr IS NOT NULL)
WHERE 
    am.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND (year(years.production_year) = 2020 OR years.production_year IS NULL)
GROUP BY 
    ak.name, am.title, years.series_years
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    ranking, actor_name;
