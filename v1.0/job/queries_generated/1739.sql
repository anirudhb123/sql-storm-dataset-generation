WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title AS Top_Movie_Title,
    tm.production_year AS Production_Year,
    ak.name AS Actor_Name,
    COUNT(*) OVER (PARTITION BY tm.movie_id) AS Total_Actors,
    COALESCE(ki.keyword, 'No Keyword') AS Keyword
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
ORDER BY 
    tm.production_year DESC, 
    Total_Actors DESC, 
    tm.title;
