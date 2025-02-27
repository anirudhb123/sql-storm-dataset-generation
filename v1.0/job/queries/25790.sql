WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        aka_name ak ON ak.person_id = m.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        name c ON c.id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
Ranking AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        cast_names,
        keywords,
        companies,
        RANK() OVER (ORDER BY production_year DESC) AS rank_by_year
    FROM 
        MovieDetails
)
SELECT 
    rank_by_year,
    movie_title,
    production_year,
    aka_names,
    cast_names,
    keywords,
    companies
FROM 
    Ranking
WHERE 
    rank_by_year <= 10
ORDER BY 
    production_year DESC;
