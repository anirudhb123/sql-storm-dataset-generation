WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No Keywords') AS keywords,
        COALESCE(GROUP_CONCAT(DISTINCT c.name), 'No Companies') AS companies,
        COUNT(DISTINCT p.person_id) AS actor_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        name n ON n.id = ci.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year ASC) AS rn
    FROM 
        MovieDetails md
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keywords,
    r.companies,
    r.actor_count,
    r.avg_roles
FROM 
    RankedMovies r
WHERE 
    r.rn <= 10
    AND r.avg_roles > 0.5
ORDER BY 
    r.actor_count DESC;
