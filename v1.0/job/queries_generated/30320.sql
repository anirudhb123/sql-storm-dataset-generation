WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
        COUNT(mh.movie_id) OVER (PARTITION BY mh.production_year) AS total_in_year
    FROM 
        MovieHierarchy mh
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    rm.title,
    rm.production_year,
    rm.title_rank,
    rm.total_in_year,
    cr.role,
    cr.role_count,
    cs.company_name,
    cs.company_type,
    cs.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoleCounts cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    CompanyStatistics cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank, 
    cr.role NULLS LAST;
