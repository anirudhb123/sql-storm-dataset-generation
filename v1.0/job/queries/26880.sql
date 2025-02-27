WITH ActorMovieCounts AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        a.id,
        a.name AS actor_name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    ORDER BY 
        amc.movie_count DESC 
    LIMIT 10
),
MovieGenreCounts AS (
    SELECT 
        m.production_year,
        kt.kind AS genre,
        COUNT(m.id) AS movie_count
    FROM 
        aka_title m
    JOIN 
        kind_type kt ON m.kind_id = kt.id
    GROUP BY 
        m.production_year, kt.kind
),
RecentGenres AS (
    SELECT 
        production_year,
        genre,
        movie_count
    FROM 
        MovieGenreCounts
    WHERE 
        production_year > 2010
),
ActorDetails AS (
    SELECT 
        ta.actor_name,
        STRING_AGG(DISTINCT rg.genre || ' (' || rg.movie_count || ')', ', ') AS genres_with_count
    FROM 
        TopActors ta
    JOIN 
        cast_info ci ON ta.id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    JOIN 
        RecentGenres rg ON mt.production_year = rg.production_year
    GROUP BY 
        ta.actor_name
)
SELECT 
    ad.actor_name,
    ad.genres_with_count
FROM 
    ActorDetails ad
WHERE 
    ad.genres_with_count IS NOT NULL
ORDER BY 
    ad.actor_name;
