
WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS production_year,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.name, t.title, t.production_year, ct.kind
), CompanyPerformance AS (
    SELECT 
        cs.name AS company_name,
        COUNT(DISTINCT am.movie_title) AS total_movies,
        AVG(am.production_year) AS avg_release_year,
        ARRAY_AGG(DISTINCT am.actor_name) AS leading_actors
    FROM 
        company_name cs
    JOIN 
        movie_companies mc ON cs.id = mc.company_id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    JOIN 
        ActorMovies am ON t.title = am.movie_title
    GROUP BY 
        cs.name
)
SELECT 
    cp.company_name,
    cp.total_movies,
    cp.avg_release_year,
    cp.leading_actors
FROM 
    CompanyPerformance cp
WHERE 
    cp.total_movies > 10
ORDER BY 
    cp.avg_release_year DESC;
