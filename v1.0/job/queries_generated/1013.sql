WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ma.actor_count, 0) AS actor_count,
    cd.companies,
    CASE 
        WHEN ma.actor_count IS NULL THEN 'No actors'
        WHEN ma.actor_count > 10 THEN 'Blockbuster'
        ELSE 'Indie'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieActors ma ON rm.movie_id = ma.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
