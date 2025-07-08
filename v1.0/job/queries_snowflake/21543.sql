
WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year 
                           ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON ci.movie_id = m.id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        mk.movie_id
),
incomplete_cast_movies AS (
    SELECT
        DISTINCT c.movie_id
    FROM
        cast_info c
    WHERE
        c.note IS NULL OR c.note LIKE '%extra%'
),
final_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        (SELECT COUNT(*)
         FROM incomplete_cast_movies ic
         WHERE ic.movie_id = rm.movie_id) AS incomplete_cast
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_keywords mk ON mk.movie_id = rm.movie_id
    WHERE
        rm.rank <= 5  
)

SELECT
    fm.title AS Movie_Title,
    fm.production_year AS Production_Year,
    fm.cast_count AS Cast_Count,
    CASE 
        WHEN fm.incomplete_cast > 0 THEN 'Contains incomplete cast'
        ELSE 'Complete cast'
    END AS Cast_Status,
    fm.keywords
FROM
    final_movies fm
WHERE
    fm.production_year BETWEEN 2000 AND 2023
ORDER BY
    fm.production_year DESC,
    fm.cast_count DESC;
