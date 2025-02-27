
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS num_roles
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), 
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ci.companies, 'No Companies') AS companies,
    COALESCE(ci.company_types, 'No Types') AS company_types,
    COALESCE(kd.keywords, 'No Keywords') AS keywords,
    md.num_actors,
    md.num_roles,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.num_actors DESC) AS actor_rank
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    md.num_actors > 0
ORDER BY 
    md.production_year DESC, md.num_actors DESC;
