WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        c.note AS company_note,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, c.note
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.company_note,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.company_note,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC
LIMIT 50;
