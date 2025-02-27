WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        RankedTitles rt ON c.movie_id = rt.title_id
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > (
            SELECT AVG(movie_count)
            FROM ActorMovieCounts
        )
),
MovieGenreCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT kt.keyword) AS genre_count
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    ta.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    COALESCE(mgc.genre_count, 0) AS genre_count
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ta.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    MovieGenreCounts mgc ON rt.title_id = mgc.movie_id
WHERE 
    rt.rank_year <= 3
ORDER BY 
    genre_count DESC, rt.production_year DESC;
