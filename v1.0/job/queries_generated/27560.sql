WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN aka_name ak ON ak.person_id IN (
        SELECT DISTINCT c.person_id
        FROM cast_info c
        WHERE c.movie_id = t.id
    )
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
popular_movies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        movie_details md
    JOIN cast_info ci ON ci.movie_id = md.movie_id
    GROUP BY md.movie_id
)

SELECT 
    pm.movie_title,
    pm.production_year,
    pm.cast_count,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    popular_movies pm
JOIN movie_details md ON md.movie_id = pm.movie_id
ORDER BY 
    pm.cast_count DESC,
    pm.production_year ASC
LIMIT 10;
