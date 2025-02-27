WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
Actors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS actors
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.title = cc.movie_id
LEFT JOIN 
    Actors a ON cc.subject_id = a.person_id
GROUP BY 
    tm.title, tm.production_year, tm.total_cast
ORDER BY 
    tm.total_cast DESC
LIMIT 10;

-- The next part of the query explores movies with keywords and includes NULL handling
SELECT 
    m.title,
    k.keyword,
    COALESCE(mi.info, 'No information available') AS additional_info
FROM 
    aka_title m
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
