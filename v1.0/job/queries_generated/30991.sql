WITH RECURSIVE MovieHierarchy AS (
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
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
CastSummary AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE WHEN cr.role LIKE 'Lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info c
    JOIN 
        role_type cr ON c.role_id = cr.id
    GROUP BY 
        c.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.level,
    cs.total_cast,
    cs.lead_roles,
    coalesce(ki.keyword, 'No keywords') AS keyword,
    count(DISTINCT mi.id) AS info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastSummary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
    AND (cs.total_cast IS NULL OR cs.lead_roles > 0)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.level, keyword
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 1 
ORDER BY 
    rm.level, rm.production_year DESC;
