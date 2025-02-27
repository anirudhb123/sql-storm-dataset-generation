WITH NameCounts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        STRING_AGG(DISTINCT m.name, ', ') AS companies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    GROUP BY 
        a.name
),
TitleStats AS (
    SELECT 
        t.title,
        COUNT(DISTINCT kw.id) AS keyword_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        aka_title a ON t.id = a.id
    GROUP BY 
        t.title
),
RoleDistribution AS (
    SELECT 
        r.role AS role_type,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(m.production_year) AS avg_year
    FROM 
        role_type r
    JOIN 
        cast_info c ON r.id = c.role_id
    JOIN 
        aka_title a ON c.movie_id = a.movie_id
    JOIN 
        title m ON a.id = m.id
    GROUP BY 
        r.role
)
SELECT 
    nc.actor_name,
    nc.movie_count,
    nc.movies,
    ts.keyword_count,
    ts.avg_production_year,
    rd.role_type,
    rd.actor_count,
    rd.avg_year
FROM 
    NameCounts nc
JOIN 
    TitleStats ts ON ts.title IN (SELECT UNNEST(STRING_TO_ARRAY(nc.movies, ', '))) 
JOIN 
    RoleDistribution rd ON rd.actor_count > 0
ORDER BY 
    nc.movie_count DESC, ts.avg_production_year ASC;
