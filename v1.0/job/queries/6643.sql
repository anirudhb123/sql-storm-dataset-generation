WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ak.name AS actor_name,
        p.info AS person_info,
        k.keyword AS movie_keyword
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN person_info p ON ak.person_id = p.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
      AND c.kind = 'Distributor'
      AND ak.name IS NOT NULL
)
SELECT 
    movie_title,
    production_year,
    COUNT(DISTINCT actor_name) AS total_actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT person_info, ', ') AS additional_information
FROM MovieDetails
GROUP BY movie_title, production_year
HAVING COUNT(DISTINCT actor_name) > 5
ORDER BY production_year DESC, movie_title;
