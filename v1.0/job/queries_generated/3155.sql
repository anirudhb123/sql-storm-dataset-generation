WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ai.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ai ON t.id = ai.movie_id
    JOIN 
        aka_name a ON ai.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        actor_id,
        COUNT(movie_id) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_id
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorCounts a
    JOIN 
        MovieDetails m ON a.actor_id = m.actor_id
),
RelevantMovies AS (
    SELECT 
        m.title,
        m.production_year,
        m.actor_name,
        coalesce(SUM(CASE WHEN ki.keyword LIKE '%action%' THEN 1 ELSE 0 END), 0) AS action_count
    FROM 
        MovieDetails m
    LEFT JOIN 
        movie_keyword ki ON m.movie_id = ki.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.actor_name
)
SELECT 
    r.title,
    r.production_year,
    r.actor_name,
    r.action_count,
    ta.rank
FROM 
    RelevantMovies r
JOIN 
    TopActors ta ON r.actor_name = ta.actor_name
WHERE 
    ta.rank <= 10
ORDER BY 
    r.action_count DESC, r.production_year ASC;
