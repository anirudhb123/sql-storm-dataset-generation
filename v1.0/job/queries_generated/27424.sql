WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rnk
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aliases,
        keywords,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rnk <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS all_keywords,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_aliases
FROM 
    TopMovies tm
JOIN 
    aka_name ak ON ak.name = ANY(tm.aliases)
JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.title;
