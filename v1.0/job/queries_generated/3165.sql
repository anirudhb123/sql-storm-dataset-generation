WITH RankedTitles AS (
    SELECT 
        a.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.person_id,
    rt.title,
    rt.production_year,
    mwk.keywords,
    ci.company_names,
    ci.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MoviesWithKeywords mwk ON rt.title = mwk.title
LEFT JOIN 
    CompanyInfo ci ON rt.production_year = ci.movie_id 
WHERE 
    rt.rank = 1 
    AND rt.production_year >= 2000
ORDER BY 
    rt.production_year DESC, rt.person_id;
