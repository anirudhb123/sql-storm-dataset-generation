WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        CASE 
            WHEN p.gender = 'M' THEN 'Male' 
            WHEN p.gender = 'F' THEN 'Female'
            ELSE 'Unknown' 
        END AS gender
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        name p ON ci.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%Drama%'
),
AggregatedData AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies,
        COUNT(DISTINCT person_name) AS total_actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS production_companies,
        STRING_AGG(DISTINCT gender, ', ') AS actors_gender
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    total_movies,
    total_actors,
    keywords,
    production_companies,
    actors_gender
FROM 
    AggregatedData
ORDER BY 
    production_year DESC;
