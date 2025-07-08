WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movies_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.movies_in_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        grp.company_count,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        (SELECT 
            movie_id, COUNT(*) AS company_count
         FROM 
            movie_companies
         GROUP BY 
            movie_id) AS grp ON mc.movie_id = grp.movie_id
    GROUP BY 
        mc.movie_id, grp.company_count
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(ar.unique_roles, 0) AS total_unique_roles,
    md.company_count,
    md.production_companies,
    CASE 
        WHEN md.production_companies > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_production_company,
    EXISTS (
        SELECT 1 
        FROM aka_name an 
        WHERE an.person_id IN (
            SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id
        )
        AND an.name ILIKE '%' || LEFT(tm.title, 3) || '%'
    ) AS title_related_actors
FROM 
    TopMovies tm
LEFT JOIN 
    ActorRoles ar ON tm.movie_id = ar.movie_id
LEFT JOIN 
    MovieCompanyDetails md ON tm.movie_id = md.movie_id
WHERE 
    tm.movies_in_year >= 10
ORDER BY 
    tm.production_year DESC, tm.title;
