WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) as rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_id, 
    tm.movie_title, 
    tm.production_year, 
    ak.name AS actor_name, 
    pi.info AS person_info,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    (pi.info_type_id IS NULL OR pi.info_type_id NOT IN (SELECT id FROM info_type WHERE info = 'NULL Info'))
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
