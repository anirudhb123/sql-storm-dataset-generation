WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
),
ActorStatistics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        COUNT(DISTINCT production_year) AS unique_years,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    total_movies,
    unique_years,
    keywords
FROM 
    ActorStatistics
ORDER BY 
    total_movies DESC
LIMIT 10;
