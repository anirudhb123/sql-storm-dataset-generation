WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        mk.keyword IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title, 
        mh.keyword,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.keyword ORDER BY mh.level DESC) AS rank
    FROM 
        movie_hierarchy mh
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS num_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.keyword,
    rm.level,
    rm.rank,
    COALESCE(cs.num_companies, 0) AS num_companies,
    COALESCE(cs.company_names, 'No Companies') AS company_names
FROM 
    ranked_movies rm
LEFT JOIN 
    company_stats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.rank = 1
    AND rm.keyword IS NOT NULL
ORDER BY 
    rm.level DESC, 
    rm.title;
