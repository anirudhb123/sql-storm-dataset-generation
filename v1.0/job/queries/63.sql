WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
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
    WHERE 
        mc.company_type_id IS NOT NULL
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
    rt.title,
    rt.production_year,
    ac.actor_count,
    ci.company_count,
    ci.company_names,
    mk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCount ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
