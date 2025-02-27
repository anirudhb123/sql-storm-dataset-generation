WITH RecursiveMovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t 
    WHERE 
        t.kind_id IS NOT NULL
),
TitleKeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
FilteredKeywords AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        CASE 
            WHEN k.phonetic_code IS NULL THEN 'unknown'
            ELSE k.phonetic_code
        END AS phonetic_code_description
    FROM 
        keyword k
    WHERE 
        LENGTH(k.keyword) > 3
),
CastRoleDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role LIKE '%actor%'
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Independent') AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalResult AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        k.keyword_count,
        cr.role,
        COALESCE(cc.company_name, 'N/A') AS production_company,
        cc.company_rank
    FROM 
        RecursiveMovieTitles r
    LEFT JOIN 
        TitleKeywordCounts k ON r.title_id = k.movie_id
    LEFT JOIN 
        CastRoleDetails cr ON r.title_id = cr.movie_id
    LEFT JOIN 
        MovieCompanyDetails cc ON r.title_id = cc.movie_id
    WHERE 
        r.title_rank <= 5
        AND (k.keyword_count > 0 OR cr.role IS NOT NULL)
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT role || ' ' || COALESCE(cr.role_count::text, '0') ORDER BY role) AS roles,
    COALESCE(MAX(company_name), 'No Companies') AS Production_Companies
FROM 
    FinalResult
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC, title;
