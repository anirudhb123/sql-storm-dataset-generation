
WITH ActorMovieInfo AS (
    SELECT 
        ak.id AS actor_id, 
        ak.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year AS movie_year,
        k.keyword AS movie_keyword,
        ci.nr_order AS actor_order,
        pc.role AS character_role
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN role_type pc ON ci.role_id = pc.id
    WHERE 
        ak.name IS NOT NULL
        AND t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
ActorMovieRanked AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        movie_year,
        movie_keyword,
        actor_order,
        character_role, 
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY actor_order) AS rank
    FROM ActorMovieInfo
),
FilteredResults AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        movie_year,
        movie_keyword,
        character_role
    FROM ActorMovieRanked
    WHERE rank <= 5 
)
SELECT 
    actor_name,
    LISTAGG(movie_title || ' (' || movie_year || ') - ' || character_role, ', ' ) WITHIN GROUP (ORDER BY movie_year DESC) AS movie_roles
FROM FilteredResults
GROUP BY actor_name
ORDER BY actor_name;
