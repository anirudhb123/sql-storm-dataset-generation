
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),

CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type,
        m.title AS movie_title,
        COUNT(m.id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        aka_title a ON mc.movie_id = a.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title m ON a.movie_id = m.id
    GROUP BY 
        c.id, c.name, ct.kind, m.title
    HAVING 
        COUNT(m.id) > 3
),

UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

TitleDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(kw.keywords, 'No keywords') AS keywords,
        RANK() OVER (ORDER BY m.production_year) AS production_rank
    FROM 
        title m
    LEFT JOIN 
        UniqueKeywords kw ON m.id = kw.movie_id
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ci.name AS company_name,
    ci.movie_title,
    td.keywords,
    td.production_rank,
    CASE 
        WHEN td.production_rank IS NULL THEN 'N/A'
        ELSE CONCAT('Rank: ', td.production_rank)
    END AS rank_display
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyInfo ci ON ci.movie_title = rt.title
LEFT JOIN 
    TitleDetails td ON rt.title_id = td.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC,
    ci.movie_count DESC NULLS LAST,
    ci.name;
