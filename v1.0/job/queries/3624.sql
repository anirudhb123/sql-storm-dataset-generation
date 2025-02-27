
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS actor_count,
    COALESCE(md.actor_names, 'No actors') AS actor_names,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.company_names, 'No companies') AS company_names,
    COALESCE(kw.keywords, 'No keywords') AS keywords
FROM 
    MovieDetails md
FULL OUTER JOIN 
    CompanyInfo ci ON md.production_year = ci.movie_id
FULL OUTER JOIN 
    MovieKeywords kw ON md.production_year = kw.movie_id
ORDER BY 
    md.production_year DESC, md.title;
