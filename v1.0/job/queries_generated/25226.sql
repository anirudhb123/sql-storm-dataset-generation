WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
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
    tm.movie_title,
    tm.production_year,
    a.name AS actor_name,
    r.role AS role_name,
    ci.note AS cast_note,
    c.name AS company_name,
    m.info AS movie_info
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON tm.movie_id = m.movie_id
WHERE 
    m.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    tm.production_year DESC, 
    a.name;
