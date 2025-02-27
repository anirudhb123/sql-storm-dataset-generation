WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        COALESCE(rp.name, 'Unknown') AS director,
        0 AS level
    FROM aka_title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN aka_name rp ON cn.imdb_id = rp.person_id
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        COALESCE(ac.name, 'Unknown') AS director,
        level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title ac ON ml.linked_movie_id = ac.id 
    WHERE ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.director,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    MAX(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS has_lead_role,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_list,
    DENSE_RANK() OVER (PARTITION BY mh.director ORDER BY mh.movie_id) AS movie_rank
FROM MovieHierarchy mh
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN role_type r ON r.id = (SELECT DISTINCT role_id FROM cast_info ci WHERE ci.movie_id = mh.movie_id AND ci.person_id = (SELECT person_id FROM aka_name WHERE name = mh.director LIMIT 1) LIMIT 1)
GROUP BY mh.movie_id, mh.title, mh.director
HAVING COUNT(mc.company_id) > 2 -- focus on movies with more than 2 production companies
ORDER BY mh.director, movie_rank;

-- Additional analysis for cyclical references
WITH CycleDetection AS (
    SELECT ml.movie_id, ml.linked_movie_id, ROW_NUMBER() OVER (PARTITION BY ml.movie_id ORDER BY ml.linked_movie_id) AS rn
    FROM movie_link ml
    WHERE ml.linked_movie_id IN (SELECT movie_id FROM movie_link WHERE linked_movie_id = ml.movie_id)
    HAVING COUNT(*) > 1
)
SELECT 
    cd.movie_id,
    COUNT(cd.linked_movie_id) AS cycles_found
FROM CycleDetection cd
GROUP BY cd.movie_id
HAVING COUNT(cd.linked_movie_id) > 1;
