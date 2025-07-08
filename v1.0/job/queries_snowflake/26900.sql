WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mci.company_id) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        ac.actor_count
    FROM 
        RankedMovies rm
    JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.rank <= 10
)
SELECT 
    md.title,
    md.production_year,
    kt.kind,
    md.actor_count
FROM 
    MovieDetails md
JOIN 
    kind_type kt ON md.kind_id = kt.id
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
