WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title t
    INNER JOIN 
        cast_info ci ON t.id = ci.movie_id
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    INNER JOIN 
        role_type r ON ci.role_id = r.id
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),

KeywordSummary AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT movie_keyword) AS keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
),

MovieActorSummary AS (
    SELECT 
        movie_title,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)

SELECT 
    m.movie_title,
    m.production_year,
    k.keyword_count,
    a.actors,
    a.roles,
    STRING_AGG(DISTINCT m.company_name || ' (' || m.company_type || ')', '; ') AS production_companies
FROM 
    MovieDetails m
JOIN 
    KeywordSummary k ON m.movie_title = k.movie_title
JOIN 
    MovieActorSummary a ON m.movie_title = a.movie_title
GROUP BY 
    m.movie_title, m.production_year, k.keyword_count, a.actors, a.roles
ORDER BY 
    m.production_year DESC, k.keyword_count DESC;
