WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        n.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    JOIN 
        name n ON a.person_id = n.imdb_id
    WHERE 
        amc.movie_count > (
            SELECT 
                AVG(movie_count)
            FROM 
                ActorMovieCounts
        )
),
ActorAwardInfo AS (
    SELECT 
        t.movie_id,
        t.title,
        COUNT(DISTINCT CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS award_count
    FROM 
        title t 
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    LEFT JOIN 
        person_info pi ON pi.person_id = cc.subject_id
    GROUP BY 
        t.movie_id, t.title
),
HighAwardMovies AS (
    SELECT 
        movie_id,
        title
    FROM 
        ActorAwardInfo
    WHERE 
        award_count > 3
)
SELECT 
    ta.name AS actor_name,
    hm.title AS award_movie,
    RANK() OVER (PARTITION BY ta.actor_id ORDER BY hm.title) AS rank_within_actor
FROM 
    TopActors ta
LEFT JOIN 
    HighAwardMovies hm ON ta.actor_id = (
        SELECT 
            c.person_id
        FROM 
            cast_info c
        WHERE 
            c.movie_id = hm.movie_id 
        LIMIT 1
    )
WHERE 
    hm.title IS NOT NULL
ORDER BY 
    ta.name, rank_within_actor;
