
WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS companies
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2022
    GROUP BY 
        m.id, m.title, m.production_year
),
PersonInfo AS (
    SELECT 
        a.person_id, 
        a.name AS actor_name, 
        STRING_AGG(DISTINCT r.role, ',') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
),
CombinedInfo AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.keywords,
        a.person_id AS actor_id,
        a.name AS actor_name,
        pi.roles
    FROM 
        MovieInfo mi
    JOIN 
        cast_info ci ON mi.movie_id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        PersonInfo pi ON a.person_id = pi.person_id
)
SELECT 
    c.movie_id,
    c.title,
    c.production_year,
    c.keywords,
    STRING_AGG(DISTINCT c.actor_name, ',') AS co_actors,
    STRING_AGG(DISTINCT c.roles, ',') AS co_roles
FROM 
    CombinedInfo c
GROUP BY 
    c.movie_id,
    c.title,
    c.production_year,
    c.keywords
ORDER BY 
    c.production_year DESC;
