WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        c.name AS company_name,
        a.name AS actor_name,
        t.production_year,
        k.keyword AS movie_keyword,
        p.info AS actor_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'USA'
        AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
),
AggregateDetails AS (
    SELECT 
        movie_title,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(production_year) AS latest_year
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    movie_title,
    actors,
    companies,
    keywords,
    latest_year
FROM 
    AggregateDetails
ORDER BY 
    latest_year DESC;
