
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    m.movie_id, 
    m.title, 
    m.production_year,
    n.name AS director_name,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    RankedMovies m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    name n ON cc.subject_id = n.imdb_id
WHERE 
    cn.country_code = 'USA'
GROUP BY 
    m.movie_id, m.title, m.production_year, n.name
ORDER BY 
    m.production_year DESC;
