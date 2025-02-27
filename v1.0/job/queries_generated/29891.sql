WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(a.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        keywords,
        cast_count,
        companies,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
    WHERE 
        production_year > 1990
)
SELECT 
    rank,
    movie_title,
    production_year,
    aka_names,
    keywords,
    cast_count,
    companies
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;

This SQL query retrieves the top 10 movies produced after 1990 based on their cast count, displaying several relevant details, including alternate names (aka_names), associated keywords, and production companies. It utilizes Common Table Expressions (CTEs) to organize the data efficiently.
