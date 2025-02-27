
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, m.name
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_name,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_name,
    tm.cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    TopMovies tm
LEFT JOIN 
    aka_title at ON tm.movie_id = at.movie_id
LEFT JOIN 
    aka_name ak ON at.id = ak.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.company_name, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
