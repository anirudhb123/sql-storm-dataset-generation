WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        keyword_count,
        companies
    FROM 
        MovieStats
    ORDER BY 
        actor_count DESC, 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    title,
    production_year,
    actor_count,
    keyword_count,
    companies
FROM 
    TopMovies;
