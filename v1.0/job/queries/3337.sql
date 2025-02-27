WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.actor_count,
        rm.rank_by_actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_actors <= 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS actor_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
)
SELECT 
    tm.movie_title,
    tm.actor_count,
    ad.actor_name,
    ad.actor_movie_rank
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON tm.movie_title = ad.movie_title
WHERE 
    (ad.actor_movie_rank <= 3 OR ad.actor_movie_rank IS NULL)
ORDER BY 
    tm.actor_count DESC, tm.movie_title;
