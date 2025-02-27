WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title AS mt
    WHERE 
        mt.epi od_of_id IS NULL
    
    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1,
        CAST(mh.path || ' > ' || mt.title AS VARCHAR(255))
    FROM 
        aka_title AS mt
    INNER JOIN MovieHierarchy AS mh ON mt.episode_of_id = mh.movie_id
)
SELECT 
    A.name AS actor_name,
    T.title AS movie_title,
    MH.path AS movie_path,
    T.production_year,
    COUNT(DISTINCT kc.keyword) FILTER (WHERE kc.keyword IS NOT NULL) AS keyword_count,
    COUNT(DISTINCT COALESCE(p.info, 'N/A')) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY A.name ORDER BY T.production_year DESC) AS movie_rank,
    CASE 
        WHEN COUNT(CASE WHEN C.ct.id IS NULL THEN 1 END) > 0 THEN 'Missing Cast Info'
        ELSE 'Complete'
    END AS cast_info_status
FROM 
    aka_name AS A
JOIN 
    cast_info AS C ON A.person_id = C.person_id
JOIN 
    aka_title AS T ON C.movie_id = T.movie_id
LEFT JOIN 
    movie_keyword AS mk ON T.id = mk.movie_id
LEFT JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info AS p ON A.person_id = p.person_id 
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
LEFT JOIN 
    MovieHierarchy AS MH ON MH.movie_id = T.id
WHERE 
    T.production_year IS NOT NULL
GROUP BY 
    A.name, T.title, MH.path, T.production_year
HAVING 
    COUNT(DISTINCT C.id) > 0 
    OR COUNT(DISTINCT T.id) > 1
ORDER BY 
    movie_rank, actor_name;
