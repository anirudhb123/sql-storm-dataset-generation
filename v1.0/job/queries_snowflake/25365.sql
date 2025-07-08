
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') AS actor_names,
        LISTAGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        a.title, a.production_year, c.name
),
TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count,
        actor_names,
        movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS row_num
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    company_name,
    cast_count,
    actor_names,
    movie_keywords
FROM 
    TopRankedMovies
WHERE 
    row_num <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
