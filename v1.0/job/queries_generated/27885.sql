WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_kind,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_kind,
        actors,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(actors) DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    company_kind,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rn <= 5
ORDER BY 
    production_year, company_kind;
