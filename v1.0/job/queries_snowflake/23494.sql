
WITH RecursiveTopMovies AS (
    SELECT
        t.title,
        t.production_year,
        COALESCE(mi.info, 'No Info Available') AS movie_info,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rnk
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary' LIMIT 1)
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.title, t.production_year, mi.info
    HAVING
        COUNT(DISTINCT c.person_id) > 5
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        movie_info,
        rnk
    FROM 
        RecursiveTopMovies
    WHERE 
        rnk <= 10
),
KeyWordCounts AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        FilteredMovies mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = mt.title LIMIT 1)
    GROUP BY 
        mt.title
)
SELECT 
    ft.title,
    ft.production_year,
    ft.movie_info,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN ft.production_year < 2000 THEN 'Classic'
        WHEN ft.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS time_category
FROM 
    FilteredMovies ft
LEFT JOIN 
    KeyWordCounts kc ON ft.title = kc.title
ORDER BY 
    ft.production_year DESC, keyword_count DESC;
