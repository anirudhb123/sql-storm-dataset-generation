WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT cn.name) AS character_names
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        char_name cn ON ci.person_role_id = cn.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        character_names,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.character_names
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC;
