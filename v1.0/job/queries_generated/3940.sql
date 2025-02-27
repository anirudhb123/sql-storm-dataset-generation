WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN pi.info_type_id = 1 THEN LENGTH(pi.info) ELSE NULL END) AS avg_person_info_length,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    LEFT JOIN 
        person_info AS pi ON c.person_id = pi.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword
    FROM 
        RankedMovies AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        m.cast_count > 10
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        MoviesWithKeywords
    GROUP BY 
        title, 
        production_year
    ORDER BY 
        production_year DESC
)
SELECT 
    tm.title,
    tm.production_year,
    CASE 
        WHEN tm.keywords IS NULL THEN 'No keywords available'
        ELSE tm.keywords 
    END AS keywords,
    COALESCE(rm.cast_count, 0) AS total_cast
FROM 
    TopMovies AS tm
LEFT JOIN 
    RankedMovies AS rm ON tm.title = rm.title AND tm.production_year = rm.production_year
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    )
ORDER BY 
    tm.production_year DESC, tm.title;
