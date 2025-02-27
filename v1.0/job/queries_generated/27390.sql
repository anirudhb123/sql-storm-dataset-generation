WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND cn.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, a.name
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.director_name,
    m.cast_count,
    STRING_AGG(DISTINCT m.keywords::text, ', ') AS keywords
FROM 
    RankedMovies m
GROUP BY 
    m.movie_id, m.title, m.production_year, m.director_name, m.cast_count
ORDER BY 
    m.production_year DESC;
