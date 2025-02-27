WITH ranked_movies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(ci.person_id) AS cast_count,
        AVG(pi.score) AS avg_rating
    FROM aka_title a
    LEFT JOIN cast_info ci ON a.movie_id = ci.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            AVG(rating) AS score
        FROM movie_info 
        WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        GROUP BY movie_id
    ) pi ON a.movie_id = pi.movie_id
    GROUP BY a.id, a.title, a.production_year, a.kind_id
), filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.avg_rating
    FROM ranked_movies rm
    WHERE rm.avg_rating IS NOT NULL
    AND rm.cast_count > 5
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), final_output AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.cast_count,
        fm.avg_rating,
        mk.keywords
    FROM filtered_movies fm
    LEFT JOIN movie_keywords mk ON fm.movie_id = mk.movie_id
)
SELECT 
    fo.title,
    fo.production_year,
    fo.cast_count,
    fo.avg_rating,
    fo.keywords
FROM final_output fo
WHERE fo.production_year >= 2000
ORDER BY fo.avg_rating DESC, fo.cast_count DESC
LIMIT 10;
