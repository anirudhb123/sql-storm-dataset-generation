WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        rn,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        company_type ct ON c.id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        c.nm_order AS actor_order,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
),
TitleKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    COALESCE(NULLIF(cti.name, ''), 'Unknown Company') AS company_name,
    COALESCE(NULLIF(tk.keywords, ''), 'No Keywords') AS associated_keywords,
    COUNT(DISTINCT mc.actor_name) AS total_actors,
    AVG(MOD(mc.actor_order, 5)) AS avg_mod_order
FROM 
    RankedTitles rt
LEFT JOIN 
    movie_companies mc ON rt.id = mc.movie_id
LEFT JOIN 
    CompanyInfo cti ON mc.company_id = cti.company_id
LEFT JOIN 
    TitleKeywords tk ON rt.id = tk.movie_id
LEFT JOIN 
    MovieCast mc ON rt.id = mc.movie_id
WHERE 
    rt.production_year > 2000
    OR (rt.production_year IS NULL AND mc.actor_name IS NOT NULL)
GROUP BY 
    rt.title, rt.production_year, cti.name, tk.keywords
HAVING 
    COUNT(DISTINCT mc.actor_name) > 2
ORDER BY 
    rt.production_year DESC, rt.title ASC;
