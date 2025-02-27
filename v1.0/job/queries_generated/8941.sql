WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_count
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_title,
    tm.production_year,
    a.name AS actor_name,
    c.kind AS role_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    tm.rank_count <= 10
GROUP BY 
    tm.movie_id, a.name, c.kind
ORDER BY 
    tm.cast_count DESC, tm.movie_title;
