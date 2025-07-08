
WITH ranked_movies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rnk
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.title, t.production_year
),
top_movies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM ranked_movies rm
    WHERE rm.rnk <= 5
),
company_movie_info AS (
    SELECT
        c.name AS company_name,
        m.production_year,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN aka_title t ON mc.movie_id = t.movie_id
    JOIN title m ON t.movie_id = m.id
    GROUP BY c.name, m.production_year
)
SELECT
    t.title,
    t.production_year,
    t.cast_count,
    COALESCE(cm.company_name, 'No Company') AS company_name,
    COALESCE(cm.movie_titles, 'No titles') AS movie_titles
FROM top_movies t
LEFT JOIN company_movie_info cm ON t.production_year = cm.production_year
ORDER BY t.production_year DESC, t.cast_count DESC;
