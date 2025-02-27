WITH MovieDetails AS (
    SELECT t.title, 
           t.production_year, 
           a.name AS actor_name, 
           c.kind AS role_type,
           COUNT(DISTINCT m.id) AS num_companies, 
           STRING_AGG(DISTINCT comp.name, ', ') AS company_names
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type c ON ci.role_id = c.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name comp ON mc.company_id = comp.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, a.name, c.kind
),
ActorDetails AS (
    SELECT a.person_id, 
           a.name AS actor_name, 
           a.surname_pcode, 
           a.imdb_index,
           STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY a.person_id, a.name, a.surname_pcode, a.imdb_index
)
SELECT md.title, 
       md.production_year, 
       md.actor_name, 
       md.role_type, 
       md.num_companies, 
       md.company_names, 
       ad.keywords
FROM MovieDetails md
JOIN ActorDetails ad ON md.actor_name = ad.actor_name
ORDER BY md.production_year DESC, md.title;
