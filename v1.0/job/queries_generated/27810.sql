WITH actor_movie_list AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        mi.info AS movie_info,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY a.name, t.title, t.production_year, ct.kind, mi.info
),
benchmarked_actors AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        company_type,
        movie_info,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS rn
    FROM actor_movie_list
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    company_type,
    movie_info,
    keywords
FROM benchmarked_actors
WHERE rn <= 5
ORDER BY actor_name, production_year DESC;
