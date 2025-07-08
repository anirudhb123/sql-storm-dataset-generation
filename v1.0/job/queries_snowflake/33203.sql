
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        title m
    WHERE 
        m.production_year >= 2020  

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        title m ON m.episode_of_id = mh.movie_id  
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

CastRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_list
    FROM 
        cast_info ci
    JOIN 
        name n ON ci.person_id = n.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),

MovieCompanies AS (
    SELECT
        mc.movie_id,
        LISTAGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mk.keywords,
    cr.total_cast,
    cr.cast_list,
    mc.companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cr.total_cast DESC) AS rank_by_cast
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    CastRoles cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    MovieCompanies mc ON mh.movie_id = mc.movie_id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year > 2010)  
    AND (cr.total_cast IS NULL OR cr.total_cast > 0)  
ORDER BY 
    mh.production_year DESC,
    rank_by_cast;
