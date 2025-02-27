WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mt.kind, 'Unknown') AS type,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(kt.kind, 'Unknown') AS type,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.type,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.type ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
),
distinct_keywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.type,
    rm.level,
    rm.rank,
    COALESCE(dk.keywords, '{}') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    distinct_keywords dk ON rm.movie_id = dk.movie_id
WHERE 
    rm.rank <= 5 
    AND (rm.production_year > 2015 OR rm.type = 'Documentary')
ORDER BY 
    rm.type, rm.production_year DESC;
