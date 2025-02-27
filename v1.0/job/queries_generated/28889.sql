WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        m.info AS movie_info
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_info m ON t.id = m.movie_id
    WHERE t.production_year >= 2000
    AND ci.nr_order < 5 -- Limit to first 5 actors only
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(actor_name || ' (' || actor_role || ')', ', ') AS actor_list,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT movie_info, ', ') AS additional_info
FROM movie_details
GROUP BY movie_title, production_year
ORDER BY production_year DESC, movie_title;
