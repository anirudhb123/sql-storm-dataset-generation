WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        SUM(CASE WHEN ca.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_roles,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ca ON a.id = ca.movie_id
    GROUP BY a.title, a.production_year, c.name
),
ranked_movies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS year_rank
    FROM movie_details md
)
SELECT 
    r.title,
    r.production_year,
    r.company_name,
    r.keywords,
    r.actor_count,
    r.cast_roles,
    COALESCE(info.info, 'No additional info') AS additional_info
FROM ranked_movies r
LEFT JOIN movie_info mi ON r.production_year = mi.movie_id
LEFT JOIN movie_info_idx info ON mi.id = info.id
WHERE r.year_rank <= 10 -- Top 10 movies per year
AND r.actor_count > 0 -- Must have at least one actor
ORDER BY r.production_year DESC, r.actor_count DESC;
