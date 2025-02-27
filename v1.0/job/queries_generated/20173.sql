WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(st.season_nr, 0) AS season_nr,
        COALESCE(st.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title st ON mt.episode_of_id = st.id
    WHERE 
        mt.production_year IS NOT NULL 

    UNION ALL 

    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(st.season_nr, 0) AS season_nr,
        COALESCE(st.episode_nr, 0) AS episode_nr,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)
SELECT 
    akn.name AS actor_name,
    mt.title AS movie_title,
    mh.season_nr,
    mh.episode_nr,
    COUNT(mk.keyword) AS keyword_count,
    AVG(COALESCE(mr.rating, 0)) AS avg_rating,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_list,
    CASE 
        WHEN COUNT(mk.keyword) > 5 THEN 'High'
        WHEN COUNT(mk.keyword) BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low' 
    END AS keyword_intensity
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name akn ON cc.person_id = akn.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT movie_id, AVG(rating) AS rating 
     FROM movie_rating 
     GROUP BY movie_id) mr ON mh.movie_id = mr.movie_id 
WHERE 
    akn.name IS NOT NULL 
GROUP BY 
    akn.name, mt.title, mh.season_nr, mh.episode_nr
HAVING 
    COUNT(mk.keyword) IS NOT NULL
ORDER BY 
    keyword_intensity DESC, avg_rating DESC
LIMIT 10;

-- Additional complexity with NULL handling
SELECT 
    mt.title,
    COALESCE((SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mt.id), 0) AS company_count,
    COALESCE((SELECT STRING_AGG(cn.name, ', ') FROM movie_companies mc 
               JOIN company_name cn ON mc.company_id = cn.id 
               WHERE mc.movie_id = mt.id), 'No companies') AS company_names
FROM 
    aka_title mt
WHERE 
    mt.production_year >= 2000 AND (mt.kind_id IS NULL OR mt.kind_id <> 3)
ORDER BY 
    company_count DESC, mt.title
OFFSET 5 ROWS;
