WITH movie_summary AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN r.role = 'director' THEN 1 ELSE 0 END) AS total_directors,
        SUM(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END) AS total_actors,
        STRING_AGG(DISTINCT CASE WHEN c.note IS NOT NULL THEN c.note END, ', ') AS notes
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN role_type r ON c.role_id = r.id
    GROUP BY a.id
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
),
final_summary AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.total_directors,
        ms.total_actors,
        ks.keywords,
        CASE 
            WHEN ms.total_cast = 0 THEN 'N/A'
            ELSE CAST((ms.total_directors::decimal / ms.total_cast) * 100 AS NUMERIC(5,2))
        END AS director_percentage,
        COALESCE(ms.notes, 'No notes available') AS notes
    FROM movie_summary ms
    LEFT JOIN keyword_summary ks ON ms.title = ks.movie_id
)
SELECT 
    title,
    production_year,
    total_cast,
    total_directors,
    total_actors,
    keywords,
    director_percentage,
    notes
FROM final_summary
WHERE total_cast > 0
ORDER BY production_year DESC, total_cast DESC
LIMIT 100;
