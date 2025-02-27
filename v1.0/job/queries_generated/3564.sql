WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id) 
LEFT JOIN 
    cast_info c ON cc.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, actor_count DESC
LIMIT 10;
