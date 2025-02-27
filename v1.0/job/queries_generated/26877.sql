WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        k.keyword AS movie_keyword,
        ci.kind AS company_type,
        pi.info AS person_info
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
        AND a.name ILIKE '%John%'
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS cast,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_type, ', ') AS production_companies,
        STRING_AGG(DISTINCT person_info, ', ') AS person_infos
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    cast,
    keywords,
    production_companies,
    person_infos
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;
