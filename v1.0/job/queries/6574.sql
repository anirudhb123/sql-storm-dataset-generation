
WITH movie_details AS (
    SELECT t.title, t.production_year, STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
           STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.title, t.production_year
),
actor_details AS (
    SELECT a.name AS actor_name, t.title, t.production_year, r.role
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type r ON ci.role_id = r.id
    WHERE r.role IN ('Actor', 'Actress')
),
combined_details AS (
    SELECT md.title, md.production_year, md.keywords, md.companies, ad.actor_name, ad.role
    FROM movie_details md
    JOIN actor_details ad ON md.title = ad.title AND md.production_year = ad.production_year
)
SELECT title, production_year, keywords, companies, STRING_AGG(DISTINCT actor_name || ' as ' || role, ', ') AS actors
FROM combined_details
GROUP BY title, production_year, keywords, companies
ORDER BY production_year DESC, title;
