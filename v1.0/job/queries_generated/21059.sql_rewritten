WITH CTE_TitleRoles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ct.kind AS role_kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON rt.id = ct.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, ct.kind
),
CTE_MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
CTE_TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CTE_Final AS (
    SELECT 
        tr.title_id,
        tr.title,
        tr.role_kind,
        tr.cast_count,
        tr.avg_order,
        mc.company_count,
        mc.company_names,
        tk.keywords
    FROM 
        CTE_TitleRoles tr
    LEFT JOIN 
        CTE_MovieCompanies mc ON tr.title_id = mc.movie_id
    LEFT JOIN 
        CTE_TitleKeywords tk ON tr.title_id = tk.movie_id
)
SELECT 
    title_id,
    title,
    role_kind,
    cast_count,
    avg_order,
    COALESCE(company_count, 0) AS company_count,
    COALESCE(company_names, 'No Companies') AS company_names,
    COALESCE(keywords, 'No Keywords') AS keywords
FROM 
    CTE_Final
WHERE 
    (cast_count > 0 OR avg_order IS NOT NULL)
    AND (company_count IS NOT NULL AND company_count > 2)
ORDER BY 
    title ASC, cast_count DESC
LIMIT 50;