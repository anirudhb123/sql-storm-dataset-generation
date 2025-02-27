
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(mn.name) AS main_actor
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name mn ON c.person_id = mn.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.main_actor, 'No Actors') AS main_actor,
    COALESCE(kd.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.companies, 'No Companies') AS companies
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordDetails kd ON md.title_id = kd.movie_id
LEFT JOIN 
    CompanyDetails cd ON md.title_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
