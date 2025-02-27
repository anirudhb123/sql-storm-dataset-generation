WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        p.info AS actor_info
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN person_info p ON a.person_id = p.person_id AND p.info_type_id IN (
        SELECT id FROM info_type WHERE info IN ('bio', 'birth_date')
    )
    WHERE t.production_year >= 2000 AND c.country_code = 'USA'
),
performance_benchmark AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS cast,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies
    FROM movie_details
    GROUP BY movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    cast,
    keywords,
    companies
FROM performance_benchmark
ORDER BY production_year DESC, movie_title;
