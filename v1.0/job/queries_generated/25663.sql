WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_type,
        actors,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actors) DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    company_type,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, rank;
