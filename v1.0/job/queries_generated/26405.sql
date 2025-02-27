WITH MovieTitles AS (
    SELECT 
        a.id AS movie_id, 
        a.title AS title, 
        a.production_year,
        k.keyword AS main_keyword,
        COALESCE(mci.note, 'No Notes') AS company_note
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mci ON a.id = mci.movie_id
    WHERE 
        a.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
ActorMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        ar.actor_name,
        ar.role_name
    FROM 
        MovieTitles mt
    JOIN 
        ActorRoles ar ON mt.movie_id = ar.movie_id
)
SELECT 
    am.title AS movie_title,
    am.production_year,
    STRING_AGG(DISTINCT am.actor_name || ' (' || am.role_name || ')', ', ') AS cast,
    COUNT(DISTINCT am.actor_name) AS total_actors,
    MAX(mt.company_note) AS company_information
FROM 
    ActorMovies am
JOIN 
    MovieTitles mt ON am.movie_id = mt.movie_id
GROUP BY 
    am.title, am.production_year
ORDER BY 
    am.production_year DESC, 
    movie_title;
