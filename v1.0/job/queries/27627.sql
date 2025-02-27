WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
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
    rt.company_count,
    ci.actor_count,
    ci.actor_names,
    kc.keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CastInfo ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    KeywordCount kc ON rt.title_id = kc.movie_id
WHERE 
    rt.company_count > 0
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;