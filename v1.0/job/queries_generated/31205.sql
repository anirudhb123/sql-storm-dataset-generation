WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1 AS level
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mt.movie_id,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        movie_companies mc
    INNER JOIN 
        aka_title mt ON mc.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.kind AS movie_kind,
        c.name AS company_name
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        kind_type k ON t.kind_id = k.id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    m.total_keywords,
    m.total_roles,
    CASE
        WHEN m.total_cast > 20 THEN 'Popular'
        WHEN m.total_cast BETWEEN 10 AND 20 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity_class,
    COALESCE(SUM(d.movie_kind) OVER (PARTITION BY d.movie_kind), 'N/A') AS kind_summary
FROM 
    top_movies m
LEFT JOIN 
    movie_details d ON m.movie_id = d.title_id
WHERE 
    m.rn <= 10
ORDER BY 
    m.production_year DESC, m.total_cast DESC

UNION ALL

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    NULL AS total_cast,
    NULL AS total_keywords,
    NULL AS total_roles,
    'Archived' AS popularity_class,
    'No Data' AS kind_summary
FROM 
    movie_hierarchy mh
WHERE 
    mh.level > 2
ORDER BY 
    production_year DESC;
