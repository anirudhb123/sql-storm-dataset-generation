WITH RECURSIVE MovieHier AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        MovieHier mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5 
    AND 
        mt.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.person_id, 
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.person_id, ak.name
),
RoleStatistics AS (
    SELECT 
        pr.person_id, 
        pr.name,
        pr.movie_count,
        ROW_NUMBER() OVER (ORDER BY pr.movie_count DESC) AS rank,
        CASE 
            WHEN pr.movie_count = 0 THEN 'No roles'
            WHEN pr.movie_count BETWEEN 1 AND 5 THEN 'Minor role'
            WHEN pr.movie_count BETWEEN 6 AND 15 THEN 'Supporting role'
            ELSE 'Lead role'
        END AS role_classification
    FROM 
        PersonRoles pr
),
KeywordCounts AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TitleKeywordRole AS (
    SELECT 
        a.title AS movie_title,
        ak.name AS actor_name,
        rk.role_classification,
        kc.keyword_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        RoleStatistics rk ON ak.person_id = rk.person_id
    JOIN 
        KeywordCounts kc ON a.id = kc.movie_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    tkr.movie_title,
    COUNT(DISTINCT tkr.actor_name) AS total_actors,
    SUM(CASE WHEN tkr.role_classification = 'Lead role' THEN 1 ELSE 0 END) AS lead_role_count,
    MAX(tkr.keyword_count) AS max_keywords,
    STRING_AGG(DISTINCT tkr.actor_name, ', ') AS actor_names 
FROM 
    TitleKeywordRole tkr
GROUP BY 
    tkr.movie_title
HAVING 
    COUNT(DISTINCT tkr.actor_name) > 2 
ORDER BY 
    max_keywords DESC, total_actors DESC
LIMIT 10;