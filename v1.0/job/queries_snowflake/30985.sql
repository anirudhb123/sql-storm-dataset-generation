WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS hierarchy_level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.hierarchy_level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id 
    WHERE 
        mh.hierarchy_level < 3
),

RolePlayerCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),

CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(rc.role_count, 0) AS role_count,
        COALESCE(cc.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RolePlayerCounts rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        CompanyCounts cc ON mh.movie_id = cc.movie_id
)

SELECT 
    ms.title,
    ms.production_year,
    ms.role_count,
    ms.company_count,
    CASE 
        WHEN ms.role_count > 5 THEN 'Large Cast'
        WHEN ms.role_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN ms.company_count > 3 THEN 'Collaborative Production'
        ELSE 'Solo Production'
    END AS production_style
FROM 
    MovieStats ms
WHERE 
    ms.rank <= 10
ORDER BY 
    ms.production_year DESC;
