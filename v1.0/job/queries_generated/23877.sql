WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        0 AS level,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mh.level + 1,
        at.title,
        at.production_year,
        mh.title_path || at.title
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE at.production_year BETWEEN 2000 AND 2020
),
actor_info AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(CASE WHEN ci.nr_order = 1 THEN ka.name END) AS lead_role,
        STRING_AGG(DISTINCT at.title, ', ') AS movie_titles
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    LEFT JOIN aka_title at ON ci.movie_id = at.id
    WHERE ka.name IS NOT NULL AND ci.person_role_id IS NOT NULL
    GROUP BY ka.person_id, ka.name
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    a.name AS actor_name,
    a.movie_count,
    a.lead_role,
    a.movie_titles,
    COALESCE(ki.keywords, ARRAY[]::text[]) AS keywords,
    mh.title AS linked_movie,
    mh.production_year
FROM actor_info a
LEFT JOIN keyword_info ki ON ki.movie_id IN (SELECT unnest(string_to_array(a.movie_titles, ', '))::int)
LEFT JOIN movie_hierarchy mh ON mh.movie_id IN (SELECT unnest(string_to_array(a.movie_titles, ', '))::int)
WHERE a.movie_count > 5
ORDER BY a.movie_count DESC, mh.level, a.name
LIMIT 50;
