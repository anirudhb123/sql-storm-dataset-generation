WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),

ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),

TopActors AS (
    SELECT 
        ac.person_id,
        an.name,
        ac.movie_count
    FROM 
        ActorMovieCount ac
    JOIN 
        aka_name an ON ac.person_id = an.person_id
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10
),

MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

MoviesWithDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COALESCE(mkc.keyword_count, 0) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieKeywordCounts mkc ON mh.movie_id = mkc.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    m.keyword_count,
    COALESCE(m.keyword_count, 0) AS keyword_count,
    COALESCE(NULLIF(a.movie_count, 0), 'No Movies') AS movie_count_band,
    CASE 
        WHEN m.keyword_count > 5 THEN 'High'
        WHEN m.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_depth
FROM 
    TopActors a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MoviesWithDetails m ON ci.movie_id = m.movie_id
WHERE 
    m.rank <= 3
ORDER BY 
    a.movie_count DESC, m.production_year ASC;
