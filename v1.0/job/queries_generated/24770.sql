WITH RECURSIVE top_movies AS (
    SELECT t.id, t.title, t.production_year, 
           COUNT(c.person_id) AS cast_count
    FROM aka_title t
    JOIN cast_info c ON t.id = c.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
    HAVING COUNT(c.person_id) > 5
),
ranked_movies AS (
    SELECT tm.*, 
           ROW_NUMBER() OVER (ORDER BY tm.cast_count DESC) AS rn
    FROM top_movies tm
    WHERE tm.production_year >= 2000
),
movie_details AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           COALESCE(ki.keyword, 'No Keywords') AS keyword, 
           STRING_AGG(DISTINCT ci.note, ', ') FILTER (WHERE ci.note IS NOT NULL) AS cast_notes
    FROM ranked_movies rm
    LEFT JOIN movie_keyword mk ON rm.id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN movie_info mi ON rm.id = mi.movie_id
    LEFT JOIN cast_info ci ON rm.id = ci.movie_id
    GROUP BY m.id, rm.title, rm.production_year
)
SELECT d.movie_id,
       d.title,
       d.production_year,
       d.keyword,
       d.cast_notes,
       ROUND(AVG(CASE WHEN pi.info_type_id = 1 THEN pi.info::numeric ELSE NULL END), 2) AS avg_rating,
       MAX(CASE WHEN NOT EXISTS (SELECT 1 FROM aka_title at WHERE at.id = d.movie_id AND at.production_year <= d.production_year) THEN 1 ELSE 0 END) AS is_first_release
FROM movie_details d
LEFT JOIN person_info pi ON d.movie_id = pi.person_id
GROUP BY d.movie_id, d.title, d.production_year, d.keyword, d.cast_notes
HAVING COUNT(DISTINCT d.keyword) > 1
ORDER BY d.production_year DESC, d.cast_notes IS NOT NULL, d.title;
