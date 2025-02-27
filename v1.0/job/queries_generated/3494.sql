WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
CoActorMovies AS (
    SELECT 
        ci1.movie_id,
        ci1.person_id AS actor1,
        ci2.person_id AS actor2
    FROM 
        cast_info ci1
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id != ci2.person_id
),
FilteredCoActors AS (
    SELECT 
        cam.actor1,
        cam.actor2,
        COUNT(DISTINCT cam.movie_id) AS co_starring_count
    FROM 
        CoActorMovies cam
    GROUP BY 
        cam.actor1, cam.actor2 
    HAVING 
        COUNT(DISTINCT cam.movie_id) > 5
)
SELECT 
    a.name,
    amc.movie_count,
    COUNT(DISTINCT fca.actor2) AS notable_co_actors
FROM 
    aka_name a
JOIN 
    ActorMovieCounts amc ON a.person_id = amc.person_id
LEFT JOIN 
    FilteredCoActors fca ON fca.actor1 = a.person_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, amc.movie_count
ORDER BY 
    amc.movie_count DESC, a.name;
