WITH MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        mi.info AS movie_info,
        k.keyword AS movie_keyword
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON mt.id = mi.movie_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
        AND ak.name IS NOT NULL
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
        AND k.keyword IS NOT NULL
),
AggregateResults AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_type, ', ') AS companies,
        STRING_AGG(DISTINCT movie_info, '; ') AS informations,
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
    informations,
    keywords
FROM 
    AggregateResults
ORDER BY 
    production_year DESC, movie_title;
