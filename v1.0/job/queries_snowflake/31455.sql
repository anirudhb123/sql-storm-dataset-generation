
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        m.movie_id AS parent_movie_id
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy m ON e.episode_of_id = m.movie_id
),

movie_cast AS (
    SELECT 
        mc.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info mc
    JOIN 
        aka_name ak ON mc.person_id = ak.person_id
),

movie_keys AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mk.keywords, 'None') AS keywords,
    COUNT(mca.actor_name) AS num_cast,
    SUM(CASE WHEN mca.actor_rank <= 3 THEN 1 ELSE 0 END) AS top_actors_count,
    CASE 
        WHEN COUNT(mca.actor_name) > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mca ON mh.movie_id = mca.movie_id
LEFT JOIN 
    movie_keys mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords
ORDER BY 
    mh.production_year DESC, mh.title;
