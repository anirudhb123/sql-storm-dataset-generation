WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS year_rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year, c.name
),
top_movies AS (
    SELECT 
        title,
        production_year,
        company_name,
        cast_names
    FROM ranked_movies
    WHERE year_rank <= 5
)
SELECT 
    production_year,
    STRING_AGG(title, ', ') AS top_titles,
    STRING_AGG(company_name, ', ') AS associated_companies,
    STRING_AGG(cast_names::text, ', ') AS main_casts
FROM top_movies
GROUP BY production_year
ORDER BY production_year DESC;
