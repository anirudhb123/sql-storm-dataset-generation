WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        K.keywords
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword K ON mk.keyword_id = K.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2022
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.total_cast,
    COALESCE((SELECT STRING_AGG(DISTINCT K.keyword, ', ')
               FROM movie_keyword mk
               JOIN keyword K ON mk.keyword_id = K.id
               WHERE mk.movie_id = tm.id), 'No keywords') AS keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10;
