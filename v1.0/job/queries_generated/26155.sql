WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
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
        rm.rank_in_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    p.name AS director_name,
    p.gender AS director_gender,
    c.name AS company_name,
    it.info AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
