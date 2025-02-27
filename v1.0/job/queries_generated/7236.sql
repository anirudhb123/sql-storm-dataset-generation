WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    an.name AS actor_name,
    cn.name AS company_name,
    kt.keyword
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.subject_id = an.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
