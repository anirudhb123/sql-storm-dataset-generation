WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name p ON ci.person_id = p.person_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year, c.name
),
avg_cast_count AS (
    SELECT 
        AVG(cast_count) AS average_cast
    FROM (
        SELECT 
            movie_id,
            COUNT(DISTINCT person_id) AS cast_count
        FROM cast_info
        GROUP BY movie_id
    ) AS cast_counts
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.keywords,
    md.cast_names,
    ac.average_cast
FROM movie_details md
CROSS JOIN avg_cast_count ac
ORDER BY md.production_year DESC, md.title ASC
LIMIT 10;
