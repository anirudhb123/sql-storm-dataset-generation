WITH MovieDetails AS (
    SELECT t.id AS movie_id, t.title, t.production_year, c.name AS company_name, 
           GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
           GROUP_CONCAT(DISTINCT ak.name) AS aka_names
    FROM aka_title ak
    JOIN title t ON ak.movie_id = t.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, c.name
),
ActorDetails AS (
    SELECT ci.movie_id, p.name AS actor_name, rt.role AS role_name
    FROM cast_info ci
    JOIN name p ON ci.person_id = p.id
    JOIN role_type rt ON ci.role_id = rt.id
),
CompleteDetails AS (
    SELECT md.movie_id, md.title, md.production_year, md.company_name, md.keywords, 
           GROUP_CONCAT(DISTINCT ad.actor_name || ' (' || ad.role_name || ')') AS actors
    FROM MovieDetails md
    LEFT JOIN ActorDetails ad ON md.movie_id = ad.movie_id
    GROUP BY md.movie_id, md.title, md.production_year, md.company_name, md.keywords
)
SELECT * 
FROM CompleteDetails 
WHERE production_year >= 2000 
ORDER BY production_year DESC, title ASC;
