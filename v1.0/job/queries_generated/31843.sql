WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM 
        MovieHierarchy mh
), ActorRoles AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.level,
    ar.roles,
    mcd.company_names,
    mcd.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, 
    rm.level ASC
LIMIT 10;
