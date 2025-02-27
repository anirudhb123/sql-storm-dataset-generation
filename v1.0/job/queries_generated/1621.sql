WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name AS p ON c.person_id = p.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
), FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        female_cast,
        male_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(f.female_cast, 0) AS female_cast,
    COALESCE(f.male_cast, 0) AS male_cast,
    COALESCE(m.info, 'No Description') AS movie_info
FROM 
    FilteredMovies AS f
LEFT JOIN 
    movie_info AS m ON f.production_year = m.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Description')
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
