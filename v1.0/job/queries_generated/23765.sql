WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        mcm.company_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_companies mcm ON mcm.movie_id = mt.id
    LEFT JOIN 
        company_name cn ON cn.id = mcm.company_id
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL 
    SELECT 
        mt.title,
        mt.production_year,
        mcm.company_id,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mt.production_year = mh.production_year 
    JOIN 
        movie_companies mcm ON mcm.movie_id = mt.id
    LEFT JOIN 
        company_name cn ON cn.id = mcm.company_id
    WHERE 
        mh.company_id <> mcm.company_id
),
cast_analytics AS (
    SELECT
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(NULLIF(mt.production_year, 0)) AS average_production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON mt.id = ci.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, ak.person_id
    HAVING 
        COUNT(ci.movie_id) > 5
),
suspicious_titles AS (
    SELECT
        at.title,
        MIN(mt.production_year) AS earliest_year,
        COUNT(DISTINCT ak.person_id) AS actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        at.title
    HAVING 
        COUNT(DISTINCT ak.person_id) IS NULL OR COUNT(DISTINCT ak.person_id) > 50
)
SELECT 
    mh.title,
    mh.production_year,
    mh.company_name,
    ca.actor_name,
    ca.movie_count,
    ca.average_production_year,
    st.title AS suspicious_title,
    st.earliest_year,
    st.actor_count
FROM 
    movie_hierarchy mh
FULL OUTER JOIN 
    cast_analytics ca ON ca.movie_count > 1
LEFT JOIN 
    suspicious_titles st ON st.title = mh.title
WHERE 
    ca.actor_rank <= 10
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    ca.movie_count DESC NULLS FIRST;
