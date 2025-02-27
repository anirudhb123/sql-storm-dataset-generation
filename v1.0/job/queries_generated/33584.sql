WITH Recursive_CTE AS (
    SELECT 
        movie_id, 
        COUNT(*) AS total_cast, 
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY person_id) AS cast_order
    FROM 
        cast_info
    GROUP BY 
        movie_id
), 
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown Year') AS production_year,
        a.name AS actor_name,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        t.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_order
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 1990
), 
AggregateData AS (
    SELECT 
        movie_title, 
        production_year,
        STRING_AGG(actor_name, ', ') AS actors,
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
    keywords,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE title = MovieDetails.movie_title)
    ) AS total_cast_count
FROM 
    MovieDetails
JOIN 
    AggregateData ON MovieDetails.movie_title = AggregateData.movie_title
WHERE 
    (SELECT COUNT(*) 
     FROM cast_info
     WHERE movie_id = MovieDetails.movie_id
    ) > 10
ORDER BY 
    production_year DESC,
    actors;
