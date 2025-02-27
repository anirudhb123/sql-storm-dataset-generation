WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name, 
    mt.title AS movie_title, 
    mt.production_year, 
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN f.name IS NOT NULL THEN 'Featured' 
        ELSE 'Regular'
    END AS feature_status,
    ROW_NUMBER() OVER(PARTITION BY ak.name ORDER BY mt.production_year DESC) AS movies_rank,
    COALESCE(COUNT( DISTINCT mk.id), 0) AS keyword_count
FROM 
    aka_name AS ak
LEFT JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy AS mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies AS mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    (SELECT 
        DISTINCT movie_id, name 
    FROM 
        complete_cast 
    GROUP BY 
        movie_id, name) AS f ON f.movie_id = mt.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND (mt.production_year BETWEEN 2000 AND 2020 OR mt.production_year IS NULL)
GROUP BY 
    ak.name, mt.title, mt.production_year, f.name
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 0
ORDER BY 
    movies_rank, actor_name DESC
LIMIT 100;
