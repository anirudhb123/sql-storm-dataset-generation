WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE mt.production_year > 2000
    GROUP BY mt.id
),
filtered_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_count,
        md.actors,
        RANK() OVER (ORDER BY md.actor_count DESC) AS rank
    FROM movie_details md
    WHERE md.actor_count > 3
),
company_movies AS (
    SELECT 
        m.title AS movie_title,
        ARRAY_AGG(cn.name ORDER BY cn.name) AS companies
    FROM aka_title m
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY m.id
)
SELECT 
    f.movie_title,
    f.production_year,
    f.actor_count,
    f.actors,
    c.companies,
    CASE 
        WHEN f.actor_count > 10 THEN 'Star-Studded'
        WHEN f.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Low Cast'
    END AS cast_evaluation
FROM filtered_movies f
LEFT JOIN company_movies c ON f.movie_title = c.movie_title
WHERE f.rank <= 20
ORDER BY f.production_year DESC, f.actor_count DESC;
