WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 
    FROM 
        movie_link ml 
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5  -- limit recursion depth
),

actor_roles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS number_of_roles,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles_description
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, ci.movie_id
),

top_actors AS (
    SELECT 
        ak.name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 2
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    ta.name AS Top_Actor,
    ta.movies_count AS Total_Movies,
    ak.roles_description AS Actor_Roles,
    mk.keywords_list AS Movie_Keywords,
    COUNT(DISTINCT mh.movie_id) OVER (PARTITION BY mh.title) AS Linked_Movies_Count,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent'
    END AS Era
FROM 
    movie_hierarchy mh
LEFT JOIN 
    top_actors ta ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
LEFT JOIN 
    actor_roles ak ON mh.movie_id = ak.movie_id AND ak.person_id = ta.person_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 3  -- top movie connections
ORDER BY 
    mh.production_year DESC, 
    COUNT(DISTINCT mh.movie_id) DESC, 
    ta.movies_count DESC
LIMIT 50;

