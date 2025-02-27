
WITH MovieDetails AS (
    SELECT t.title, t.production_year, a.name AS actor_name, ct.kind AS company_type, 
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
           COUNT(DISTINCT c.id) AS total_cast
    FROM aka_title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info c ON cc.subject_id = c.id
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, a.name, ct.kind
)
SELECT md.title, md.production_year, COUNT(DISTINCT md.actor_name) AS unique_actors, 
       COUNT(DISTINCT md.company_type) AS unique_company_types, 
       md.keywords, md.total_cast
FROM MovieDetails md
GROUP BY md.title, md.production_year, md.keywords, md.total_cast
ORDER BY md.production_year DESC, unique_actors DESC;
