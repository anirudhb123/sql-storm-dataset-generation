WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
ActorDetails AS (
    SELECT 
        ca.person_id,
        ak.name AS actor_name,
        ct.kind AS role_kind,
        COUNT(ca.movie_id) AS movie_count
    FROM 
        cast_info ca 
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ca.person_role_id = ct.id
    GROUP BY 
        ca.person_id, ak.name, ct.kind
),
TopActors AS (
    SELECT 
        actor_name,
        role_kind,
        movie_count
    FROM 
        ActorDetails
    WHERE 
        movie_count >= 3
),
MovieActorStats AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        ta.actor_name,
        ta.role_kind,
        ta.movie_count
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    JOIN 
        TopActors ta ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = ta.actor_name LIMIT 1)
)
SELECT 
    mas.movie_title,
    mas.production_year,
    mas.actor_name,
    mas.role_kind,
    mas.movie_count
FROM 
    MovieActorStats mas
ORDER BY 
    mas.production_year DESC,
    mas.movie_title;
