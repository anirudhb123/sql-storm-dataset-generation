
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.total_movies
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 
),
ActorRoleStats AS (
    SELECT 
        c.movie_id,
        rt.role AS actor_role,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id, rt.role
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        ac.actor_role,
        ac.actor_count,
        ci.company_name,
        ci.company_type,
        COALESCE(k.keyword, 'No Keywords') AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        ActorRoleStats ac ON f.movie_id = ac.movie_id
    LEFT JOIN 
        CompanyInfo ci ON f.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON f.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_role,
        md.actor_count,
        md.company_name,
        md.company_type,
        md.keywords,
        CASE 
            WHEN md.actor_count IS NULL THEN 'Unknown Actors'
            WHEN md.actor_count > 0 THEN 'Has Actors'
            ELSE 'No Actors' 
        END AS actor_status
    FROM 
        MovieDetails md
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    LISTAGG(f.company_name, ', ') AS companies,
    MIN(f.actor_count) AS min_actors,
    MAX(f.actor_count) AS max_actors,
    AVG(f.actor_count) AS average_actors,
    COUNT(DISTINCT f.keywords) AS unique_keywords
FROM 
    FinalOutput f
WHERE 
    f.actor_status = 'Has Actors' OR f.actor_status = 'No Actors'
GROUP BY 
    f.movie_id, f.title, f.production_year
HAVING 
    COUNT(DISTINCT f.company_name) >= 2 
    AND AVG(f.actor_count) IS NOT NULL
ORDER BY 
    f.production_year DESC, f.title;
