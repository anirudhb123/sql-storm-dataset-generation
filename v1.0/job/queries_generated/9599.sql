WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT a.name, ', ') AS alias_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = cc.subject_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year,
        keyword_count,
        company_names,
        alias_names,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC) AS rnk
    FROM 
        MovieDetails
)
SELECT 
    movie_title, 
    production_year, 
    keyword_count, 
    company_names, 
    alias_names
FROM 
    TopMovies
WHERE 
    rnk <= 10;
