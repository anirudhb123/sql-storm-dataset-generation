WITH movie_summary AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_roles,
        AVG(CASE WHEN i.info IS NOT NULL THEN LENGTH(i.info) ELSE NULL END) AS avg_info_length
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN person_info pi ON c.person_id = pi.person_id
    LEFT JOIN movie_info i ON a.id = i.movie_id
    GROUP BY a.title, a.production_year
),
ranked_movies AS (
    SELECT
        movie_title,
        production_year,
        total_cast,
        total_roles,
        avg_info_length,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC, total_roles DESC) AS rank
    FROM movie_summary
)
SELECT 
    r.movie_title,
    r.production_year,
    r.total_cast,
    r.total_roles,
    r.avg_info_length,
    (SELECT COUNT(*) FROM ranked_movies WHERE production_year = r.production_year) AS total_movies_in_year
FROM ranked_movies r
WHERE r.rank <= 5
ORDER BY r.production_year DESC, r.total_cast DESC;
