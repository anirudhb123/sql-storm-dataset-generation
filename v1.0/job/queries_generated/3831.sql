WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(ac.movie_count, 0) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        ActorMovieCounts ac ON a.person_id = ac.person_id
),
TopActors AS (
    SELECT 
        ad.name,
        ad.movie_count,
        RANK() OVER (ORDER BY ad.movie_count DESC) AS actor_rank
    FROM 
        ActorDetails ad
    WHERE 
        ad.movie_count > 5
)
SELECT 
    tm.title,
    tm.production_year,
    ta.name AS actor_name,
    ta.movie_count,
    mk.keywords
FROM 
    RankedMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    TopActors ta ON ci.person_id = ta.actor_id
LEFT JOIN 
    MoviesWithKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank_by_year <= 10
ORDER BY 
    tm.production_year DESC, 
    ta.movie_count DESC;
