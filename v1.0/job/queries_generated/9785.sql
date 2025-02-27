WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL
    GROUP BY a.id, a.name
), 
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.name) AS company_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title, t.production_year
)
SELECT 
    am.actor_name,
    am.movie_count,
    STRING_AGG(DISTINCT md.title || ' (' || md.production_year || ')', ', ') AS movies,
    STRING_AGG(DISTINCT c.company_names, ', ') AS companies,
    STRING_AGG(DISTINCT k.keywords, ', ') AS all_keywords
FROM ActorMovies am
JOIN MovieDetails md ON am.movie_count > 0
JOIN LATERAL (SELECT DISTINCT unnest(md.company_names) AS company_names) c ON true
JOIN LATERAL (SELECT DISTINCT unnest(md.keywords) AS keywords) k ON true
GROUP BY am.actor_name, am.movie_count
ORDER BY am.movie_count DESC;
