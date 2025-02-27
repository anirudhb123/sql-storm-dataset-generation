WITH RecursiveCast AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.role_id,
        c.nr_order,
        COALESCE(p.name, 'Unknown') AS person_name,
        COALESCE(ak.name, 'No Alias') AS person_alias
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        name p ON p.id = c.person_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT mk.keyword ORDER BY mk.keyword) AS keywords,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        m.id, cn.name
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keywords,
        md.company_name,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.movie_title) AS title_rank,
        RANK() OVER (ORDER BY md.production_year DESC) AS year_rank
    FROM 
        MovieDetails md
),
CorrelatedSubquery AS (
    SELECT 
        rc.person_id,
        COUNT(DISTINCT rc.movie_id) AS movie_count,
        SUM(CASE WHEN r.role_id IS NOT NULL THEN 1 ELSE 0 END) AS confirmed_roles
    FROM 
        RecursiveCast rc
    JOIN 
        role_type r ON r.id = rc.role_id
    GROUP BY 
        rc.person_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keywords,
    rm.company_name,
    rc.person_name,
    rc.person_alias,
    r.movie_count,
    r.confirmed_roles,
    COUNT(*) OVER (PARTITION BY rm.production_year) AS movies_in_year,
    CASE 
        WHEN r.confirmed_roles > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS actor_status
FROM 
    RankedMovies rm
LEFT JOIN 
    RecursiveCast rc ON rc.movie_id = rm.movie_id
LEFT JOIN 
    CorrelatedSubquery r ON r.person_id = rc.person_id
WHERE 
    rm.production_year IS NOT NULL
    AND (rm.company_name IS NOT NULL OR rm.keywords IS NOT NULL)
    AND (rc.nr_order IS NULL OR rc.nr_order < 0 OR rc.nr_order > 5)
ORDER BY 
    rm.production_year DESC, rm.title_rank ASC, rc.person_name;
