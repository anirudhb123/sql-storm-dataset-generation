WITH RECURSIVE movie_hierarchy AS (
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
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit to a depth of 5 levels
)
SELECT 
    mh.title,
    mh.production_year,
    ak.name AS actor_name,
    ak.name_pcode_cf,
    c.name AS company_name,
    c.country_code,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ak.name) AS actor_rank,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(mh.production_year AS VARCHAR)
    END AS year_label,
    COALESCE(wc.kind, 'No Genre') AS genre_type
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    kind_type wc ON k.phonetic_code = wc.kind
WHERE 
    mh.production_year IS NOT NULL
    AND (mh.level = 1 OR c.country_code IS NOT NULL)   -- Filter for direct movies or those with companies
ORDER BY 
    mh.production_year DESC, 
    mh.movie_id, 
    actor_rank
LIMIT 100;

-- Auxiliary query to get statistics on the results
WITH ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT mh.movie_id) AS movie_count,
        AVG(mh.production_year) AS avg_year,
        COUNT(*) FILTER (WHERE wc.kind IS NOT NULL) AS genre_count
    FROM 
        movie_hierarchy mh
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        kind_type wc ON k.phonetic_code = wc.kind
    GROUP BY 
        ak.name
)
SELECT 
    actor_name,
    movie_count,
    avg_year,
    genre_count,
    CASE 
        WHEN movie_count > 10 THEN 'Famous Actor'
        WHEN genre_count >= 5 THEN 'Diverse Genre'
        ELSE 'Regular Actor'
    END AS actor_category
FROM 
    ActorStats
WHERE 
    genre_count > 0
ORDER BY 
    movie_count DESC, avg_year;
