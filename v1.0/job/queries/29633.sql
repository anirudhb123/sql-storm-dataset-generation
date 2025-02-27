WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN role_type r ON ci.role_id = r.id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, k.keyword, c.kind
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.keyword ORDER BY md.production_year DESC) AS rank
    FROM movie_details md
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    company_type,
    cast_list
FROM ranked_movies
WHERE rank <= 5
ORDER BY keyword, production_year DESC;
