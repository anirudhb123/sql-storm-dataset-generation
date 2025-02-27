WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        k.keyword AS movie_keyword
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
)

SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM movie_details
GROUP BY movie_title, production_year
ORDER BY production_year DESC, movie_title;
