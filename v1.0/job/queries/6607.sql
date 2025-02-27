
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        c.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_role_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(aka_id) AS num_akas
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
    GROUP BY 
        movie_title, production_year
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.num_akas,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year LIMIT 1)
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_title, tm.production_year, tm.num_akas
ORDER BY 
    tm.production_year DESC, tm.num_akas DESC;
