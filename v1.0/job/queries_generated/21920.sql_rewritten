WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopCastMovies AS (
    SELECT 
        movie_id, title, production_year, total_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.person_id) AS distinct_cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
    TopCastMovies t
LEFT JOIN 
    cast_info c ON t.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    name p ON ak.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 3
    AND SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) > 1
ORDER BY 
    t.production_year DESC, distinct_cast_count DESC
LIMIT 10;