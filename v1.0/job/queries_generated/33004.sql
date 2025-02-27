WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mk.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY mk.keyword) AS rnk
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mk.keyword AS movie_keyword,
        mh.rnk + 1
    FROM 
        movie_hierarchy mh
    JOIN aka_title m ON mh.movie_id = m.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        mh.rnk < 5
), movie_cast AS (
    SELECT 
        c.movie_id,
        p.id AS person_id,
        p.name,
        rc.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY p.name) AS role_order
    FROM 
        cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    LEFT JOIN role_type rc ON c.role_id = rc.id
), movie_info_extended AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(substr(mi.info, 1, 20)) AS short_info,
        COALESCE(MAX(ch.note), 'No additional notes') AS additional_notes
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN complete_cast ch ON m.id = ch.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.movie_keyword,
    COALESCE(mce.company_count, 0) AS company_count,
    COALESCE(mce.short_info, 'N/A') AS short_info,
    COALESCE(cast_names.names, 'No cast') AS cast_names
FROM 
    movie_hierarchy mh
LEFT JOIN movie_info_extended mce ON mh.movie_id = mce.movie_id
LEFT JOIN (
    SELECT 
        mc.movie_id,
        STRING_AGG(name, ', ') AS names
    FROM 
        movie_cast mc
    GROUP BY 
        mc.movie_id
) cast_names ON mh.movie_id = cast_names.movie_id
WHERE 
    mh.rnk <= 5
ORDER BY 
    mh.production_year DESC, mh.title;
