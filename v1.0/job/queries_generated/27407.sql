WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ka.name) AS actors,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mw ON mt.id = mw.movie_id
    LEFT JOIN 
        keyword kw ON mw.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        keywords,
        company_count,
        RANK() OVER (ORDER BY company_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.actors,
    t.keywords,
    t.company_count,
    t.rank
FROM 
    TopMovies t
WHERE 
    t.rank <= 10
ORDER BY 
    t.rank;
