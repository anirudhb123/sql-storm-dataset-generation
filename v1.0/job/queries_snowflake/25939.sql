
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS companies,
        COALESCE(ARRAY_AGG(DISTINCT a.name), ARRAY_CONSTRUCT()) AS actors
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        companies,
        actors,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY ARRAY_SIZE(actors) DESC) AS actor_rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    companies,
    actors
FROM 
    TopMovies
WHERE 
    actor_rank <= 5
ORDER BY 
    production_year DESC, 
    actor_rank;
