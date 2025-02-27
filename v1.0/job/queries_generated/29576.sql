WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, a.name
    ORDER BY 
        cast_count DESC, t.production_year DESC
    LIMIT 10
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.director_name,
    rm.cast_count,
    rm.keywords,
    COUNT(DISTINCT ci.person_id) AS unique_actors
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON ci.movie_id = rm.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.director_name, rm.cast_count, rm.keywords
ORDER BY 
    unique_actors DESC;
