WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword,
        c.name AS company_name,
        ci.role_id,
        a.name AS actor_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    AND 
        ci.nr_order = 1
),
RoleSummary AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year, 
        COUNT(DISTINCT md.actor_name) AS total_actors,
        COUNT(DISTINCT md.keyword) AS total_keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.title, md.production_year
)
SELECT 
    rs.movie_id, 
    rs.title, 
    rs.production_year, 
    rs.total_actors,
    rs.total_keywords,
    rs.production_companies
FROM 
    RoleSummary rs
ORDER BY 
    rs.production_year DESC, 
    rs.total_actors DESC;
