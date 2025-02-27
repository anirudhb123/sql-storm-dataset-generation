WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

ActorDetail AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS num_movies,
        AVG(m.production_year) AS avg_production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        ak.name
),

TitleKeyword AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.title 
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ad.actor_name,
    ad.num_movies,
    ad.avg_production_year,
    tk.keywords,
    COALESCE(NULLIF(mh.production_year, 0), 'N/A') AS production_year_display
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorDetail ad ON ad.num_movies > 5 
LEFT JOIN 
    TitleKeyword tk ON mh.title = tk.title
WHERE 
    mh.production_year IS NOT NULL
    AND mh.level = 1
ORDER BY 
    mh.production_year DESC,
    ad.num_movies DESC;

