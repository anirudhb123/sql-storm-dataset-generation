WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.rank,
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT keyword_id) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY movie_id
    ) mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE production_year = rm.production_year)
    WHERE 
        rm.rank <= 3
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keyword_count,
    COALESCE(ai.name, 'Unknown') AS actor_name
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
LEFT JOIN 
    aka_name an ON an.person_id = ci.person_id
LEFT JOIN 
    name ai ON ai.id = an.person_id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
