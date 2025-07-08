
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        aka_names, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5  
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.aka_names, 
    tm.cast_count,
    ARRAY_AGG(DISTINCT c.kind) AS company_types
FROM 
    TopMovies AS tm
LEFT JOIN 
    movie_companies AS mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_type AS c ON mc.company_type_id = c.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.aka_names, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
