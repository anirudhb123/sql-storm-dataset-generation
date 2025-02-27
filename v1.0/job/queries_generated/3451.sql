WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
RoleCount AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS cast_rank,
        COALESCE(rc.role_count, 0) AS leading_role_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        RoleCount rc ON md.movie_id = rc.movie_id AND rc.role = 'Lead'
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_count,
    rm.cast_rank,
    CASE 
        WHEN rm.leading_role_count IS NULL THEN 'No Leads' 
        ELSE 'Leads: ' || rm.leading_role_count 
    END AS lead_role_info
FROM 
    RankedMovies rm
WHERE 
    rm.cast_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_rank;
