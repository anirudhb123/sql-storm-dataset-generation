WITH MovieKeywordAggregates AS (
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
MovieInfoAggregates AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CastAggregates AS (
    SELECT 
        ci.movie_id, 
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    t.title, 
    t.production_year, 
    t.kind_id, 
    mk.keywords, 
    mi.info_details, 
    mc.company_names, 
    ca.actor_names
FROM 
    title t
LEFT JOIN 
    MovieKeywordAggregates mk ON t.id = mk.movie_id
LEFT JOIN 
    MovieInfoAggregates mi ON t.id = mi.movie_id
LEFT JOIN 
    MovieCompanies mc ON t.id = mc.movie_id
LEFT JOIN 
    CastAggregates ca ON t.id = ca.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
