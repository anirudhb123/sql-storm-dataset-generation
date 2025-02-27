WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
), TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info
FROM 
    TopMovies t
JOIN 
    cast_info ci ON t.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ci.person_id = p.person_id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Birth Date')
ORDER BY 
    t.production_year, t.title, a.name;
