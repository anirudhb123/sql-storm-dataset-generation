WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year >= 2000 AND t.kind_id IN (1, 2)  -- Filtering for movies after 2000 and specific types
    GROUP BY 
        t.title, t.production_year, ak.name
), RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        keyword_count,
        company_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC, company_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    movie_title,
    actor_name,
    keyword_count,
    company_count
FROM 
    RankedMovies
WHERE 
    rank <= 10  -- Top 10 movies per year
ORDER BY 
    production_year, rank;
