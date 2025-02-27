WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.title IS NOT NULL
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
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        kc.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        m.production_year > 2000
        AND kc.keyword LIKE '%action%'
),
TopActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ac.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count >= 5
),
MoviesWithMoreThanTwoActors AS (
    SELECT 
        f.movie_id,
        f.title,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        FilteredMovies f
    JOIN 
        cast_info ci ON f.movie_id = ci.movie_id
    GROUP BY 
        f.movie_id, f.title
    HAVING 
        COUNT(DISTINCT ci.person_id) > 2
)
SELECT 
    t.title,
    t.production_year,
    a.name AS top_actor,
    m.actor_count
FROM 
    MoviesWithMoreThanTwoActors m
JOIN 
    RankedTitles t ON m.movie_id = t.title_id
JOIN 
    TopActors a ON m.actor_count = a.movie_count
ORDER BY 
    t.production_year DESC, 
    m.actor_count DESC, 
    t.title;
