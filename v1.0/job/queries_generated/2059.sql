WITH MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NULL OR mc.note <> 'Uncredited'
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_collected
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    t.production_year,
    mc.actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mcomp.companies, 'No Companies') AS companies,
    COALESCE(mi.info_collected, 'No Info') AS additional_info,
    COUNT(*) OVER (PARTITION BY t.id) AS actor_count,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    title t
LEFT JOIN 
    MovieCast mc ON t.id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN 
    MovieCompanies mcomp ON t.id = mcomp.movie_id
LEFT JOIN 
    MovieInfo mi ON t.id = mi.movie_id
WHERE 
    t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    t.production_year DESC, mc.actor_rank;
