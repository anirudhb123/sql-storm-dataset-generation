WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS actor_names,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        COUNT(DISTINCT ci.id) AS total_cast
    FROM title t
    JOIN aka_title at ON at.movie_id = t.id
    JOIN cast_info ci ON ci.movie_id = t.id
    JOIN aka_name ak ON ak.person_id = ci.person_id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    WHERE t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (ORDER BY production_year DESC, total_cast DESC) AS rank
    FROM movie_details
)

SELECT 
    rank,
    title,
    production_year,
    actor_names,
    company_names,
    keywords,
    total_cast
FROM ranked_movies
WHERE rank <= 50
ORDER BY rank;
