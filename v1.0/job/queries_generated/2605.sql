WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(ar.role_count, 0) AS role_count,
        ar.roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCount cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_count,
    md.role_count,
    md.roles,
    CASE 
        WHEN md.company_count > 5 AND md.role_count > 3 THEN 'Blockbuster'
        WHEN md.company_count <= 5 AND md.role_count <= 3 THEN 'Indie'
        ELSE 'Moderate'
    END AS movie_type
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND (md.company_count IS NOT NULL OR md.role_count IS NOT NULL)
ORDER BY 
    md.production_year DESC, md.title ASC
FETCH FIRST 100 ROWS ONLY;
