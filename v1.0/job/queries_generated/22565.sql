WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        a.person_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, k.keyword
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_kind,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL AND c.country_code <> ''
    GROUP BY 
        mc.movie_id, c.name, ct.kind
    HAVING 
        COUNT(mc.id) > 1
),
QualifyingMovies AS (
    SELECT 
        t.*,
        ci.company_name,
        ci.company_kind,
        tk.keyword,
        tk.keyword_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyInfo ci ON rt.title_id = ci.movie_id
    LEFT JOIN 
        TitleKeywords tk ON rt.title_id = tk.movie_id
    WHERE 
        rt.rn = 1 -- Get most recent title per person
        AND (tk.keyword_count > 1 OR ci.company_count IS NOT NULL)
)
SELECT 
    qb.title,
    qb.production_year,
    qb.company_name,
    qb.company_kind,
    COALESCE(qb.keyword, 'No Keyword') AS keyword,
    CASE 
        WHEN qb.company_kind IS NULL THEN 'Independent'
        ELSE qb.company_kind
    END AS final_company_kind,
    CONCAT('Title: ', qb.title, ' | Year: ', qb.production_year, ' | Company: ', COALESCE(qb.company_name, 'N/A'), 
           ' | Keyword: ', COALESCE(qb.keyword, 'No Keyword')) AS title_summary
FROM 
    QualifyingMovies qb
WHERE 
    qb.production_year >= (SELECT MAX(production_year) FROM aka_title) - 10 -- Filter for the last 10 years
ORDER BY 
    qb.production_year DESC, qb.title;
