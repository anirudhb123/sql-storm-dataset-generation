WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        mk.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, a.name, ct.kind, mk.keyword
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_type, ', ') AS companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    companies,
    keywords
FROM 
    AggregatedData
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, movie_title;
