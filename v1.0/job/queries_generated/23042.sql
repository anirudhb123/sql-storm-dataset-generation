WITH RecursiveTitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(t2.title, 'N/A') AS parent_title,
        1 AS level
    FROM title t
    LEFT JOIN title t2 ON t.episode_of_id = t2.id
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(t2.title, 'N/A') AS parent_title,
        level + 1
    FROM title t
    JOIN RecursiveTitleHierarchy rth ON t.episode_of_id = rth.title_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        SUM(CASE WHEN ct.kind = 'lead' THEN 1 ELSE 0 END) AS lead_actor_count
    FROM cast_info ci
    LEFT JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
MovieSummaries AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        kc.total_keywords,
        cr.total_cast_members,
        cr.lead_actor_count,
        (cr.lead_actor_count::decimal / NULLIF(cr.total_cast_members, 0)) * 100 AS lead_actor_percentage
    FROM RecursiveTitleHierarchy rt
    LEFT JOIN KeywordCounts kc ON rt.title_id = kc.movie_id
    LEFT JOIN CastRoles cr ON rt.title_id = cr.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast_members,
    ms.lead_actor_count,
    ms.lead_actor_percentage,
    CASE 
        WHEN ms.lead_actor_percentage > 50 THEN 'Star-studded'
        WHEN ms.lead_actor_percentage BETWEEN 20 AND 50 THEN 'Average'
        ELSE 'Unknown'
    END AS cast_quality,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    CASE 
        WHEN EXISTS (SELECT 1 FROM aka_title WHERE title_id = ms.title_id) THEN 'Exists'
        ELSE 'Not Exists'
    END AS aka_title_existence
FROM MovieSummaries ms
LEFT JOIN aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = ms.title_id)
WHERE ms.production_year IS NOT NULL
GROUP BY 
    ms.title,
    ms.production_year,
    ms.total_cast_members,
    ms.lead_actor_count,
    ms.lead_actor_percentage
ORDER BY 
    ms.production_year DESC,
    ms.lead_actor_percentage DESC
LIMIT 100;
