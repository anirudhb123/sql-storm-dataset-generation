WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL AND 
        at.production_year > 2000
),
TopRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
FinalResult AS (
    SELECT 
        rt.title,
        rt.production_year,
        tr.roles,
        COALESCE(cd.company_name, 'No Company') AS company_name,
        COALESCE(cd.company_type, 'Unknown') AS company_type,
        COALESCE(cd.keyword_count, 0) AS keyword_count,
        COALESCE(mk.all_keywords, 'No keywords') AS keywords,
        tr.movie_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        TopRoles tr ON tr.movie_count > 5
    LEFT JOIN 
        CompanyDetails cd ON rt.title_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rt.title_id = mk.movie_id
)
SELECT 
    *,
    CASE 
        WHEN keyword_count > 10 THEN 'Highly Keyworded'
        WHEN keyword_count BETWEEN 5 AND 10 THEN 'Moderately Keyworded'
        ELSE 'Few Keywords'
    END AS keyword_rating
FROM 
    FinalResult
WHERE 
    title_rank = 1
ORDER BY 
    production_year DESC, 
    title ASC
LIMIT 100;
