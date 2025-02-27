
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, c.name
), ActorCount AS (
    SELECT title_id, COUNT(actor_names) AS actor_count
    FROM MovieDetails
    GROUP BY title_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.company_name,
    md.keywords,
    ac.actor_count
FROM MovieDetails md
JOIN ActorCount ac ON md.title_id = ac.title_id
ORDER BY md.production_year DESC, ac.actor_count DESC;
