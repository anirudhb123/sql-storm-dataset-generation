WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rn
    FROM 
        RankedMovies
)

SELECT 
    m.title,
    m.production_year,
    ak.name AS actor_name,
    k.keyword AS movie_keyword,
    p.info AS actor_info
FROM 
    TopMovies m
JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    person_info p ON p.person_id = ci.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    m.rn <= 10 
    AND m.production_year > 2000 
ORDER BY 
    m.cast_count DESC, m.production_year DESC;
