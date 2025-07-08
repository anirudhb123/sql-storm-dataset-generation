
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title m
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
actor_movies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS actor_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COALESCE(ct.kind, 'Unknown Type') AS company_type,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, k.keyword, ct.kind
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT md.movie_id) AS total_movies,
    LISTAGG(DISTINCT md.keyword, ', ') WITHIN GROUP (ORDER BY md.keyword) AS keywords,
    MIN(md.production_year) AS first_movie_year,
    MAX(md.production_year) AS last_movie_year,
    MAX(md.actor_count) AS max_actors_in_a_movie
FROM 
    actor_movies a
JOIN 
    movie_details md ON a.movie_title = md.title
WHERE 
    a.actor_movie_rank <= 5
GROUP BY 
    a.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;
