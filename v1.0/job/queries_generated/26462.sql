WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, keyword_count DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info AS cc ON t.id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL 
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
        RankedMovies AS rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    tm.keyword_count,
    tm.cast_count,
    GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS co_star_names,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS production_companies
FROM 
    TopMovies AS tm
LEFT JOIN 
    cast_info AS ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.keyword_count, tm.cast_count
ORDER BY 
    tm.production_year DESC;
