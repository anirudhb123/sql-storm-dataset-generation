
WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.name IS NOT NULL
    GROUP BY a.name, t.title, t.production_year, ct.kind
),
TopActors AS (
    SELECT 
        actor_name, 
        COUNT(movie_title) AS movie_count
    FROM ActorMovies
    GROUP BY actor_name
    ORDER BY movie_count DESC
    LIMIT 10
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    am.company_type,
    am.keywords
FROM ActorMovies am
JOIN TopActors ta ON am.actor_name = ta.actor_name
ORDER BY am.production_year DESC, am.movie_title;
