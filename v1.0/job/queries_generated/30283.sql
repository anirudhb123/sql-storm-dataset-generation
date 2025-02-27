WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(c.name, ''), 'Unknown') AS company_name,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mt.production_year >= 2000

    UNION ALL 

    SELECT 
        m.id,
        m.title,
        m.production_year,
        'N/A' AS company_name,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.company_name,
        ROW_NUMBER() OVER (PARTITION BY mh.company_name ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        movie_hierarchy mh
),
company_casts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        movie_companies mc
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.year_rank,
    COALESCE(cc.cast_count, 0) AS cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.year_rank = 1 THEN 'Latest'
        ELSE 'Older'
    END AS movie_category
FROM 
    ranked_movies rm
LEFT JOIN 
    company_casts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.company_name, 
    rm.production_year DESC;
