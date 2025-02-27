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
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
actor_stats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_starred,
        STRING_AGG(DISTINCT at.title, ', ') AS titles_starred,
        AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE NULL END) AS avg_prod_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        aka_title at ON ci.movie_id = at.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_hierarchy mh ON mh.movie_id = ci.movie_id
    GROUP BY 
        ak.name
),
movie_info_summary AS (
    SELECT 
        mt.production_year,
        COUNT(DISTINCT mt.id) AS total_movies,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(COALESCE(mi.info_type_id IS NOT NULL, 0)::int) AS info_types_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    GROUP BY 
        mt.production_year
)
SELECT 
    as.actor_name,
    as.movies_starred,
    as.titles_starred,
    as.avg_prod_year,
    COUNT(DISTINCT mh.movie_id) AS linked_movies_count,
    mis.total_movies,
    mis.total_actors,
    mis.info_types_count
FROM 
    actor_stats as
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id IN (
        SELECT 
            movie_id 
        FROM 
            cast_info 
        WHERE 
            person_id IN (SELECT person_id FROM aka_name WHERE name = as.actor_name)
    )
INNER JOIN 
    movie_info_summary mis ON mis.production_year = as.avg_prod_year
WHERE 
    as.movies_starred > 1
GROUP BY 
    as.actor_name, as.movies_starred, as.titles_starred, as.avg_prod_year,
    mis.total_movies, mis.total_actors, mis.info_types_count
ORDER BY 
    as.movies_starred DESC, as.avg_prod_year DESC;
