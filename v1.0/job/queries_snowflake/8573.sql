
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        LISTAGG(DISTINCT n.name, ', ') AS cast_members
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        a.title, a.production_year
),
KeywordMovies AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
)
SELECT 
    rm.movie_title, 
    rm.production_year, 
    rm.total_cast, 
    rm.cast_members, 
    LISTAGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMovies km ON rm.production_year = (SELECT MAX(production_year) FROM RankedMovies)
GROUP BY 
    rm.movie_title, rm.production_year, rm.total_cast, rm.cast_members
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC
LIMIT 10;
