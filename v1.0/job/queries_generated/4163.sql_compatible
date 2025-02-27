
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        m.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        title m ON a.id = m.imdb_id
    WHERE 
        cn.country_code IS NOT NULL
        AND m.production_year IS NOT NULL
    GROUP BY 
        a.title, m.production_year
), 
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    TopMovies tm
UNION ALL
SELECT 
    CONCAT('Unknown Movie ', t.id) AS movie_title,
    NULL AS production_year,
    NULL AS cast_size_category
FROM 
    title t
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = t.id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'Title'
        )
    )
ORDER BY 
    production_year DESC NULLS LAST, 
    cast_size_category;
