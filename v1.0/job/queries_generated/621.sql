WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        ActorMovieCount amc ON a.person_id = amc.person_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 -- Top 5 newest movies per year
)
SELECT 
    am.actor_id,
    am.name,
    COUNT(DISTINCT fm.movie_id) AS featured_movie_count,
    MAX(fm.production_year) AS last_featured_year
FROM 
    ActorDetails am
LEFT JOIN 
    cast_info ci ON am.actor_id = ci.person_id
LEFT JOIN 
    FilteredMovies fm ON ci.movie_id = fm.movie_id
GROUP BY 
    am.actor_id, am.name
HAVING 
    COUNT(DISTINCT fm.movie_id) > (SELECT AVG(movie_count) FROM ActorMovieCount)
ORDER BY 
    last_featured_year DESC NULLS LAST;
