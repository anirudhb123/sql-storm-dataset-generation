WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name,
        COUNT(*) AS num_movies
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(*) > 5  
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    COUNT(DISTINCT ta.name) AS top_actor_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS year_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopActors ta ON ta.movie_id = mh.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords
ORDER BY 
    mh.production_year DESC, top_actor_count DESC;