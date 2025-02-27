WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword
), RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        movie_keyword,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast_count
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    company_name,
    movie_keyword,
    cast_count,
    rank_by_cast_count
FROM 
    RankedMovies
WHERE 
    rank_by_cast_count <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
