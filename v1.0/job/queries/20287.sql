WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
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
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
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
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ac.actor_count, 0) AS number_of_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.company_names, 'No Companies') AS production_companies,
    COALESCE(cd.company_types, 'No Company Types') AS company_types
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCount ac ON rt.title_id = ac.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    rt.rn = 1
    AND (rt.production_year >= 2000 OR cd.company_names IS NOT NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;