WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        r.role,
        a.name AS actor_name
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
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%drama%'
),
ActorStatistics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title) AS movie_count,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)

SELECT 
    actor_name,
    movie_count,
    keywords,
    companies
FROM 
    ActorStatistics
ORDER BY 
    movie_count DESC, actor_name;
