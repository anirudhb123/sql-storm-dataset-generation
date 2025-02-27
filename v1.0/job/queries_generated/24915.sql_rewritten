WITH MovieRolesCTE AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS lead_actor_count,
        AVG(CASE WHEN C.role = 'lead' THEN 1 ELSE 0 END) AS lead_ratio
    FROM 
        cast_info ci
    JOIN 
        role_type C ON ci.role_id = C.id
    GROUP BY 
        ci.movie_id
),
MovieTitleCTE AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        rt.role AS leading_role
    FROM 
        aka_title at
    LEFT JOIN 
        role_type rt ON at.kind_id = rt.id
    WHERE 
        at.production_year > 2000
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    COALESCE(mr.lead_actor_count, 0) AS lead_actor_count,
    COALESCE(mr.lead_ratio, 0) AS lead_ratio,
    COALESCE(kw.keywords, 'No keywords') AS movie_keywords,
    CASE 
        WHEN COALESCE(mr.lead_ratio, 0) > 0.5 
        THEN 'Popular' 
        ELSE 'Niche' 
    END AS movie_type,
    EXTRACT(YEAR FROM cast('2024-10-01' as date)) - mt.production_year AS age_of_movie
FROM 
    MovieTitleCTE mt
LEFT JOIN 
    MovieRolesCTE mr ON mt.title_id = mr.movie_id
LEFT JOIN 
    KeywordCTE kw ON mt.title_id = kw.movie_id
WHERE 
    mt.production_year IS NOT NULL
    AND (mt.leading_role IS NULL OR mt.leading_role <> 'supporting')
ORDER BY 
    age_of_movie DESC,
    lead_ratio DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;