
WITH MovieStats AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year IS NOT NULL AND a.production_year >= 2000
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        ms.title,
        ms.production_year,
        ms.cast_count
    FROM
        MovieStats ms
    WHERE
        ms.cast_count > (SELECT AVG(cast_count) FROM MovieStats)
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    CASE 
        WHEN tm.cast_count IS NULL THEN 'No Cast'
        WHEN tm.cast_count >= 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)), 0) AS info_count
FROM 
    TopMovies tm
LEFT JOIN
    (SELECT title, AVG(cast_count) AS avg_cast FROM MovieStats GROUP BY title) avg_casts ON tm.title = avg_casts.title
WHERE 
    (avg_casts.avg_cast IS NULL OR tm.cast_count > avg_casts.avg_cast)
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
