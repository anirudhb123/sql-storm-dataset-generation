WITH movie_cast AS (
    SELECT m.title AS movie_title,
           m.production_year,
           a.name AS actor_name,
           ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_rank
    FROM aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
),
company_info AS (
    SELECT m.title AS movie_title,
           co.name AS company_name,
           ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN aka_title m ON mc.movie_id = m.id
),
keyword_info AS (
    SELECT m.title AS movie_title,
           k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
),
actor_details AS (
    SELECT mc.movie_title,
           mc.production_year,
           mc.actor_name,
           mc.actor_rank,
           co.company_name,
           co.company_type,
           k.keyword
    FROM movie_cast mc
    LEFT JOIN company_info co ON mc.movie_title = co.movie_title
    LEFT JOIN keyword_info k ON mc.movie_title = k.movie_title
)
SELECT movie_title,
       production_year,
       actor_name,
       STRING_AGG(DISTINCT company_name, ', ') AS companies,
       STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM actor_details
WHERE production_year >= 2000 AND actor_name IS NOT NULL
GROUP BY movie_title, production_year, actor_name
ORDER BY production_year DESC, actor_rank
LIMIT 50;
