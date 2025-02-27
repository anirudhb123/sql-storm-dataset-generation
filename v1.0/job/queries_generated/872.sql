WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MIN(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) AS has_actors,
        SUM(CASE WHEN ak.name IS NULL THEN 1 ELSE 0 END) AS null_actor_names_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_names,
    COALESCE(ci.companies, 'No Companies') AS companies,
    ci.company_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    md.has_actors,
    md.null_actor_names_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON md.movie_id = mk.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.actor_count DESC;
