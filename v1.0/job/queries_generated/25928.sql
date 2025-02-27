WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MostPopularMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
Actors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
)
SELECT 
    mp.title,
    mp.production_year,
    mp.company_count,
    mp.keyword_count,
    a.name AS actor_name,
    a.movie_count
FROM 
    MostPopularMovies mp
JOIN 
    cast_info ci ON mp.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
ORDER BY 
    mp.production_year DESC, 
    mp.company_count DESC, 
    a.movie_count DESC;
