WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank_per_year
    FROM aka_title at
    WHERE at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorMovieList AS (
    SELECT 
        ak.name AS actor_name,
        rm.movie_title,
        rm.production_year,
        COUNT(ci.id) AS role_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN RankedMovies rm ON ci.movie_id = (SELECT movie_id 
                                             FROM aka_title 
                                             WHERE title = rm.movie_title AND production_year = rm.production_year LIMIT 1)
    GROUP BY ak.name, rm.movie_title, rm.production_year
),
ActorStats AS (
    SELECT 
        actor_name,
        SUM(role_count) AS total_roles,
        COUNT(DISTINCT production_year) AS distinct_years,
        AVG(role_count) AS avg_roles_per_year
    FROM ActorMovieList
    GROUP BY actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        total_roles,
        distinct_years,
        avg_roles_per_year,
        ROW_NUMBER() OVER (ORDER BY total_roles DESC) AS rank
    FROM ActorStats
)
SELECT 
    ta.actor_name,
    ta.total_roles,
    ta.distinct_years,
    ta.avg_roles_per_year,
    (SELECT STRING_AGG(DISTINCT movie_title, ', ') 
     FROM ActorMovieList 
     WHERE actor_name = ta.actor_name
    ) AS movies_worked_on,
    COALESCE((SELECT COUNT(*)
              FROM person_info pi
              WHERE pi.person_id = (SELECT person_id FROM aka_name WHERE name = ta.actor_name LIMIT 1)
              AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
             ), 0) AS awards_count
FROM TopActors ta
WHERE ta.rank <= 10 AND ta.avg_roles_per_year > 0
ORDER BY ta.total_roles DESC;