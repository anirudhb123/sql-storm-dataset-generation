WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(k.keyword) AS keywords,
        COALESCE(COUNT(DISTINCT c.id), 0) AS cast_count
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.person_id
    GROUP BY m.id
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM ranked_movies
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.keywords,
    tm.cast_count,
    p.name AS actor_name,
    p.gender
FROM top_movies tm
JOIN complete_cast cc ON tm.movie_id = cc.movie_id
JOIN cast_info c ON cc.subject_id = c.person_id
JOIN aka_name p ON c.person_id = p.person_id
WHERE tm.rn <= 5
ORDER BY tm.production_year, tm.cast_count DESC, tm.movie_title;
