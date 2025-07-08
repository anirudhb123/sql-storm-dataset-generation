
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        t.production_year DESC
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    tm.production_year,
    tm.title,
    tm.cast_count,
    tm.aka_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
