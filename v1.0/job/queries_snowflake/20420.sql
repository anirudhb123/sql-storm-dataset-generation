
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS role_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CompleteCasting AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(r.role) AS primary_role
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mw.keywords, 'No keywords') AS keywords,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cd.company_type, 'Unknown Type') AS company_type,
    CAST(cc.total_cast AS INTEGER) AS total_cast_members,
    cc.primary_role AS prominent_role,
    CASE 
        WHEN cc.total_cast IS NULL THEN 'No cast found'
        WHEN cc.total_cast > 10 THEN 'Large cast'
        ELSE 'Small cast'
    END AS cast_size_category
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieWithKeywords mw ON rt.title_id = mw.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    CompleteCasting cc ON rt.title_id = cc.movie_id
WHERE 
    rt.rank_per_year = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
