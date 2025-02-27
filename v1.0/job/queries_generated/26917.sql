WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        k.keyword AS related_keyword,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM aka_title a
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY a.title, t.production_year, k.keyword
),
selected_movies AS (
    SELECT 
        movie_title,
        production_year,
        related_keyword,
        cast_count
    FROM ranked_movies
    WHERE rank = 1 AND production_year >= 2000
),
company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movie_details AS (
    SELECT 
        sm.movie_title,
        sm.production_year,
        sm.related_keyword,
        sm.cast_count,
        ci.company_name,
        ci.company_type
    FROM selected_movies sm
    LEFT JOIN company_info ci ON sm.movie_title = ci.movie_title
)
SELECT 
    md.movie_title,
    md.production_year,
    md.related_keyword,
    md.cast_count,
    COUNT(DISTINCT md.company_name) AS number_of_production_companies,
    STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies
FROM movie_details md
GROUP BY md.movie_title, md.production_year, md.related_keyword, md.cast_count
ORDER BY md.production_year DESC, md.cast_count DESC;
