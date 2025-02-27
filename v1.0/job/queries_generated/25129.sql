WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT CONCAT(ka.name, ' as ', r.role)) AS cast_info,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 AND 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_info,
        cast_count,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_info,
    cast_count,
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    rank;
