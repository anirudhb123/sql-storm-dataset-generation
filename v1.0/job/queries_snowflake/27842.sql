
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS alias_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title a
        JOIN movie_companies mc ON a.id = mc.movie_id
        JOIN company_name c ON mc.company_id = c.id
        JOIN complete_cast cc ON a.id = cc.movie_id
        JOIN cast_info ci ON cc.subject_id = ci.person_id
        LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
        LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        cast_count,
        alias_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rank,
    movie_title,
    production_year,
    company_name,
    cast_count,
    alias_names,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    rank;
