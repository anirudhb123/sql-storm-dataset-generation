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
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
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
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    ARRAY_AGG(DISTINCT md.company_name) AS companies,
    CASE 
        WHEN md.production_year > 2000 THEN 'Modern Era'
        WHEN md.production_year BETWEEN 1980 AND 2000 THEN 'Late 20th Century'
        ELSE 'Classic'
    END AS era_category
FROM 
    MovieDetails md
WHERE 
    md.actor_count IS NOT NULL OR md.company_name IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.actor_count
ORDER BY 
    md.production_year DESC, md.title ASC;
