WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        p.gender AS actor_gender,
        c.kind AS company_kind,
        m.production_year,
        k.keyword AS movie_keyword
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN person_info p ON a.person_id = p.person_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000 AND
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
),
benchmark_data AS (
    SELECT 
        movie_title,
        actor_name,
        actor_gender,
        company_kind,
        production_year,
        STRING_AGG(movie_keyword, ', ') AS keywords
    FROM movie_data
    GROUP BY movie_title, actor_name, actor_gender, company_kind, production_year
)
SELECT 
    movie_title,
    actor_name,
    actor_gender,
    company_kind,
    production_year,
    keywords
FROM benchmark_data
ORDER BY production_year DESC, actor_name ASC;
