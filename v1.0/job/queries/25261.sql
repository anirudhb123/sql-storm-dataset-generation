WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(CONCAT(a.name, ' (' , rt.role, ')'), ', ') AS full_cast,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND cn.country_code IN ('USA', 'CAN', 'GBR')
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        full_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)

SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.full_cast,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.cast_count, m.full_cast
ORDER BY 
    m.production_year DESC;
