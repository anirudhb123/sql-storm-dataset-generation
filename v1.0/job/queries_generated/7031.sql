WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
        AND ci.nr_order < 5
    GROUP BY 
        t.id, t.title, t.production_year, c.name, a.name
    HAVING 
        COUNT(DISTINCT a.id) > 1
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        company_name,
        actor_name,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    company_name,
    actor_name,
    keyword_count
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, keyword_count DESC;
