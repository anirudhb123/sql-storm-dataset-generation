WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank = 1
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    c.name AS actor_name,
    r.role AS role,
    ci.note AS cast_note
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_title = (SELECT title FROM title WHERE id = cc.movie_id)
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    name n ON a.person_id = n.imdb_id
WHERE 
    n.gender = 'M' 
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
