WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year is not null

    UNION ALL

    SELECT 
        m.id,
        CONCAT(m.title, ' - Special Edition') AS title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
actor_movie_count AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
famous_actors AS (
    SELECT 
        a.id, 
        a.name, 
        COALESCE(amc.movie_count, 0) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_count amc ON a.person_id = amc.person_id
    WHERE 
        a.name IS NOT NULL AND
        (a.name LIKE '%John%' OR a.name LIKE '%Smith%')
),
movie_keyword_summary AS (
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
actor_movie_keywords AS (
    SELECT 
        am.movie_id,
        f.name AS actor_name,
        mk.keywords
    FROM 
        complete_cast am
    JOIN 
        famous_actors f ON am.subject_id = f.id
    LEFT JOIN 
        movie_keyword_summary mk ON am.movie_id = mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS cast_count,
    SUM(CASE WHEN amk.actor_name IS NOT NULL THEN 1 ELSE 0 END) AS famous_actor_count,
    STRING_AGG(DISTINCT amk.keywords, '; ') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast c ON mh.movie_id = c.movie_id
LEFT JOIN 
    actor_movie_keywords amk ON mh.movie_id = amk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 3 AND
    SUM(CASE WHEN amk.actor_name IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    mh.production_year DESC,
    cast_count DESC;
