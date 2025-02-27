WITH RECURSIVE title_hierarchy AS (
    SELECT 
        tt.id AS title_id,
        tt.title,
        tt.production_year,
        tt.kind_id,
        1 AS depth
    FROM 
        aka_title tt 
    WHERE 
        tt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        tt.id AS title_id,
        tt.title,
        tt.production_year,
        tt.kind_id,
        depth + 1
    FROM 
        title_hierarchy th
    JOIN 
        aka_title tt ON tt.episode_of_id = th.title_id
)
SELECT 
    ak.name AS actor_name,
    MAX(tth.depth) AS max_depth,
    STRING_AGG(DISTINCT tt.title, ', ') AS related_titles,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COALESCE(NULLIF(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0), 0) AS note_present_count,
    CASE 
        WHEN EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id IN (SELECT unique movie_id FROM complete_cast c WHERE c.subject_id = ak.person_id)) 
        THEN 'Has Cast Info'
        ELSE 'No Cast Info' 
    END AS cast_info_status
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    title_hierarchy tth ON ci.movie_id = tth.title_id
LEFT JOIN 
    movie_keyword mk ON tth.title_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    ak.id
HAVING 
    MAX(tt.production_year) > 2000
ORDER BY 
    max_depth DESC NULLS LAST, keyword_count DESC;
