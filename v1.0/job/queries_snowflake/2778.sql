
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        * 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CombinedResults AS (
    SELECT  
        h.title,
        h.production_year,
        h.cast_count,
        COALESCE(t.keywords, 'No keywords') AS keywords,
        h.movie_id
    FROM 
        HighCastMovies h
    LEFT JOIN 
        TopKeywords t ON h.movie_id = t.movie_id
)
SELECT 
    c.name AS company_name, 
    COUNT(m.movie_id) AS movie_count,
    AVG(m.cast_count) AS average_cast_size
FROM 
    CombinedResults m
JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    c.country_code IS NOT NULL 
GROUP BY 
    c.name
HAVING 
    COUNT(m.movie_id) > 1 
ORDER BY 
    movie_count DESC;
