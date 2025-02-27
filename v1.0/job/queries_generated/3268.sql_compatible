
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM title m
    LEFT JOIN complete_cast c ON m.id = c.movie_id
    LEFT JOIN cast_info cc ON c.subject_id = cc.person_id
    GROUP BY m.id, m.title, m.production_year
), high_cast_movies AS (
    SELECT movie_id, title, production_year, cast_count, rank
    FROM ranked_movies
    WHERE rank <= 5
), movie_tags AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
), company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    h.title,
    h.production_year,
    h.cast_count,
    COALESCE(mt.keywords, 'No keywords') AS keywords,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.company_names, 'No companies') AS company_names
FROM high_cast_movies h
LEFT JOIN movie_tags mt ON h.movie_id = mt.movie_id
LEFT JOIN company_info ci ON h.movie_id = ci.movie_id
ORDER BY h.production_year DESC, h.cast_count DESC;
