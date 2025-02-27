WITH MovieRoles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        COUNT(*) AS total_roles,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(*) DESC) AS role_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.role_id
),
MovieKeywords AS (
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
CompanyAssociation AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS complete_count
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
)

SELECT 
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ca.companies, 'No companies') AS companies,
    COALESCE(mr.total_roles, 0) AS total_roles,
    COALESCE(mr.role_rank, 999) AS role_rank,
    cc.complete_count
FROM 
    title t
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN 
    CompanyAssociation ca ON t.id = ca.movie_id
LEFT JOIN 
    MovieRoles mr ON t.id = mr.movie_id AND mr.role_rank = 1
LEFT JOIN 
    CompleteCast cc ON t.id = cc.movie_id
WHERE 
    (t.production_year IS NULL OR t.production_year BETWEEN 1900 AND 2023)
    AND (LOWER(t.title) NOT LIKE '%unknown%' OR t.title IS NULL)
    OR 
    (EXISTS(
        SELECT 1 
        FROM aka_title at 
        WHERE at.movie_id = t.id 
        AND LOWER(at.title) LIKE '%mystery%'
    ) 
    AND (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id) > 5)
ORDER BY 
    t.production_year DESC, 
    total_roles DESC, 
    keywords ASC;
