WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn,
        COUNT(c.id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year BETWEEN 1990 AND 2023
        AND cn.country_code IS NOT NULL
),
Features AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.rn,
        m.cast_count,
        COALESCE(
            (SELECT COUNT(*)
             FROM movie_info mi
             WHERE mi.movie_id = m.movie_id
             AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')),
            0
        ) AS genre_count,
        COALESCE(
            (SELECT STRING_AGG(k.keyword, ', ') 
             FROM movie_keyword mk 
             JOIN keyword k ON mk.keyword_id = k.id
             WHERE mk.movie_id = m.movie_id), 
        'No Keywords') AS keywords
    FROM 
        RankedMovies m
    WHERE 
        m.rn <= 5 
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.genre_count,
    f.keywords,
    CASE 
        WHEN f.cast_count > 10 THEN 'Large Cast'
        WHEN f.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    CASE 
        WHEN f.rn % 2 = 0 THEN 'Even ranked'
        ELSE 'Odd ranked' 
    END AS rank_type
FROM 
    Features f
LEFT JOIN 
    aka_name an ON f.movie_id = an.id
GROUP BY 
    f.title, f.production_year, f.cast_count, f.genre_count, f.keywords, f.rn
ORDER BY 
    f.production_year DESC, f.cast_count ASC, f.title;