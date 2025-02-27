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
    EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year AS age_of_movie
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

This query is designed to benchmark performance while also taking advantage of various SQL constructs. It utilizes Common Table Expressions (CTEs) to break down the query into manageable parts, incorporates outer joins to gather information from multiple tables, and makes use of COALESCE to handle NULL values effectively. The use of string aggregation and complex predicates allows for interesting insights into the movie data, categorizing movies by popularity based on the lead actor ratio, while also considering their keywords. The ordering and fetching limited results enhance the efficiency of the query, particularly desirable in benchmarking scenarios.
