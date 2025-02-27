WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        a.name AS actor_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND k.keyword LIKE '%Action%'
),
AggregateData AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS total_actors,
        COUNT(DISTINCT company_name) AS total_companies,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    MD.movie_title,
    MD.production_year,
    AD.total_actors,
    AD.total_companies,
    AD.keywords
FROM 
    MovieDetails MD
JOIN 
    AggregateData AD ON MD.movie_title = AD.movie_title
ORDER BY 
    MD.production_year DESC, AD.total_actors DESC;
