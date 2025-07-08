WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
BestMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn = 1
)
SELECT 
    bm.movie_title,
    bm.production_year,
    bm.company_name,
    bm.cast_count,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names
FROM 
    BestMovies bm
JOIN 
    aka_name ak ON bm.movie_title ILIKE '%' || ak.name || '%'
GROUP BY 
    bm.movie_title, bm.production_year, bm.company_name, bm.cast_count
ORDER BY 
    bm.production_year DESC, bm.cast_count DESC;
