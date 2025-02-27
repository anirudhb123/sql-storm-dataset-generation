WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS TEXT) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS TEXT)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        mh.path,
        ROW_NUMBER() OVER(PARTITION BY mh.production_year ORDER BY mh.level DESC, mh.movie_title) AS rn
    FROM 
        movie_hierarchy mh
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.path,
    ct.kind AS company_type,
    COUNT(DISTINCT c.id) AS total_actors,
    SUM(CASE 
            WHEN p.gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_actors,
    MIN(CASE 
            WHEN p.gender IS NULL THEN 'Unknown' 
            ELSE p.gender 
        END) AS gender_description
FROM 
    ranked_movies r
LEFT JOIN 
    cast_info c ON r.movie_id = c.movie_id
LEFT JOIN 
    name p ON c.person_id = p.imdb_id
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    r.rn = 1
    AND r.production_year >= 2000
GROUP BY 
    r.movie_id, r.movie_title, r.production_year, r.path, ct.kind
HAVING 
    COUNT(c.id) > 0
ORDER BY 
    r.production_year DESC, r.movie_title;
