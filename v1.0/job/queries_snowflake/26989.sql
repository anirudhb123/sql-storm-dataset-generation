
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ki.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        keyword_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keyword_count,
    value AS aka_name
FROM 
    TopMovies AS tm,
    LATERAL FLATTEN(input => tm.aka_names) 
ORDER BY 
    tm.keyword_count DESC, 
    tm.production_year;
