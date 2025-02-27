
WITH MovieData AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        a.name AS actor_name,
        a.person_id,
        COALESCE(SUM(CASE WHEN cc.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS num_roles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS num_production_companies
    FROM 
        aka_title t
    JOIN 
        cast_info cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, a.name, a.person_id
),
ProductionStats AS (
    SELECT 
        md.production_year,
        md.kind_id,
        COUNT(DISTINCT md.title) AS total_movies,
        COUNT(DISTINCT md.actor_name) AS unique_actors,
        SUM(md.num_roles) AS total_roles,
        SUM(md.num_production_companies) AS total_production_companies,
        STRING_AGG(DISTINCT md.keywords, ', ') AS all_keywords
    FROM 
        MovieData md
    GROUP BY 
        md.production_year, md.kind_id
)
SELECT 
    ps.production_year,
    kt.kind AS movie_kind,
    ps.total_movies,
    ps.unique_actors,
    ps.total_roles,
    ps.total_production_companies,
    ps.all_keywords
FROM 
    ProductionStats ps
JOIN 
    kind_type kt ON ps.kind_id = kt.id
ORDER BY 
    ps.production_year DESC, 
    ps.total_movies DESC;
