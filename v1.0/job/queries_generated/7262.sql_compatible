
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    company_names,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;
