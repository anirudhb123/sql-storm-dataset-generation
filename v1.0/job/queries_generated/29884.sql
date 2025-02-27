WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Release_Year,
    tm.keyword_count AS Number_of_Keywords,
    tm.cast_names AS Cast_List
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.keyword_count DESC;
