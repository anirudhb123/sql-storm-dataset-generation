WITH RecursiveRoles AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        rt.role AS primary_role,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
TitlesWithKeywords AS (
    SELECT 
        at.id AS title_id, 
        at.title, 
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id, at.title
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
MoviesWithCompleteness AS (
    SELECT 
        ti.title, 
        ti.production_year, 
        CASE 
            WHEN cc.movie_id IS NOT NULL THEN 'Complete' 
            ELSE 'Incomplete' 
        END AS cast_status,
        count(DISTINCT ci.person_id) AS cast_count
    FROM 
        title ti
    LEFT JOIN 
        complete_cast cc ON ti.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ti.id = ci.movie_id
    GROUP BY 
        ti.title, ti.production_year, cc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(c.total_companies, 0) AS number_of_companies,
    m.cast_count,
    t.keywords,
    r.primary_role
FROM 
    MoviesWithCompleteness m
LEFT JOIN 
    CompanyDetails c ON m.title = c.movie_id
LEFT JOIN 
    RecursiveRoles r ON m.movie_id = r.movie_id AND r.role_rank = 1
LEFT JOIN 
    TitlesWithKeywords t ON m.title = t.title
WHERE 
    m.cast_status = 'Complete'
    AND m.production_year IS NOT NULL
    AND (c.number_of_companies > 2 OR c.number_of_companies IS NULL)
ORDER BY 
    m.cast_count DESC, 
    m.production_year DESC;
