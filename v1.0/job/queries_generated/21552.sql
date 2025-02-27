WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        t.title, 
        COALESCE(c.kind, 'Unknown') AS company_type,
        m.production_year,
        0 AS level
    FROM 
        aka_title t 
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id 
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(c.kind, 'Unknown') AS company_type,
        mh.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id 
    WHERE 
        mh.level < 3
), company_summary AS (
    SELECT 
        company_id, 
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_companies
    GROUP BY 
        company_id
), title_summary AS (
    SELECT 
        t.title,
        COUNT(*) AS cast_count,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title
)
SELECT 
    mh.title,
    mh.production_year,
    mh.company_type,
    ts.cast_count,
    ts.avg_order,
    (CASE 
        WHEN ts.cast_count IS NULL THEN 'No Cast'
        WHEN ts.cast_count > 2 THEN 'Featured'
        ELSE 'Minor Role'
    END) AS cast_status,
    CASE 
        WHEN mh.level IS NULL THEN 'Top Level Movie'
        ELSE 'Child Movie Level ' || mh.level
    END AS hierarchy_level,
    (SELECT 
        STRING_AGG(DISTINCT name, ', ') 
    FROM 
        aka_name 
    WHERE 
        person_id IN (
            SELECT person_id 
            FROM cast_info 
            WHERE movie_id = mh.movie_id
        )) AS cast_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    title_summary ts ON mh.title = ts.title
LEFT JOIN 
    company_summary cs ON cs.company_id = (
        SELECT company_id 
        FROM movie_companies 
        WHERE movie_id = mh.movie_id 
        LIMIT 1
    )
WHERE 
    (ts.cast_count IS NOT NULL OR cs.movie_count IS NULL)
ORDER BY 
    mh.production_year DESC, 
    ts.cast_count DESC NULLS LAST;
