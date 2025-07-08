
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopActors AS (
    SELECT 
        a.name,
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, ci.movie_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        LISTAGG(gt.kind, ', ') WITHIN GROUP (ORDER BY gt.kind) AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    JOIN 
        kind_type gt ON mt.kind_id = gt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    ta.name AS top_actor,
    mg.genres
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    TopActors ta ON rm.movie_id = ta.movie_id 
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    ac.actor_count IS NOT NULL 
    AND rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
