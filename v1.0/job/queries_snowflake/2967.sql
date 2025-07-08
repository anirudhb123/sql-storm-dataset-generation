
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieGenres AS (
    SELECT 
        at.title,
        k.keyword,
        at.production_year
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    LISTAGG(DISTINCT mg.keyword, ', ') WITHIN GROUP (ORDER BY mg.keyword) AS keywords,
    COALESCE(MAX(pi.info), 'No info available') AS personal_info
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.title = mg.title AND tm.production_year = mg.production_year
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    tm.production_year >= 2000
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, COUNT(pi.info) DESC;
