WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 is the ID for 'movie'

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT cc.id) AS total_cast,
    STRING_AGG(DISTINCT CONCAT(k.keyword, ' (' , COALESCE(cn.country_code, 'Unknown'), ')'), ', ') AS keywords,
    SUM(CASE 
            WHEN ai.info ILIKE '%Award%' THEN 1 
            ELSE 0 
        END) AS award_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info ai ON at.id = ai.movie_id AND ai.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
LEFT JOIN 
    company_name cn ON at.production_year IN (2020, 2021, 2022)  -- Example condition on production year
WHERE 
    ak.name IS NOT NULL
    AND at.title IS NOT NULL
    AND ak.name <> ''
    AND ci.note IS NULL  -- Exclude cast with notes
GROUP BY 
    ak.id, at.id
HAVING 
    COUNT(DISTINCT k.id) > 0  -- Only include actors with keywords
ORDER BY 
    rank, total_cast DESC;
