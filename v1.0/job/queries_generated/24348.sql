WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        depth + 1
    FROM 
        aka_title mt
    JOIN movie_link ml ON ml.movie_id = MovieHierarchy.movie_id
    WHERE 
        ml.linked_movie_id = mt.id
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
KeywordMovies AS (
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
DetailedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(am.movie_count, 0) AS actor_count,
        COALESCE(km.keywords, 'No Keywords') AS keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorMovies am ON mh.movie_id = am.actor_id
    LEFT JOIN 
        KeywordMovies km ON mh.movie_id = km.movie_id
),
RankedMovies AS (
    SELECT *,
           RANK() OVER (PARTITION BY production_year ORDER BY depth DESC, title) AS movie_rank
    FROM DetailedMovies
)
SELECT 
    dm.title,
    dm.production_year,
    dm.actor_count,
    dm.keywords,
    CASE 
        WHEN dm.actor_count = 0 THEN 'Unknown Actors'
        WHEN dm.actor_count < 5 THEN 'Few Actors'
        WHEN dm.actor_count BETWEEN 5 AND 10 THEN 'Moderate Actors'
        ELSE 'Many Actors'
    END AS actor_category
FROM 
    RankedMovies dm
WHERE 
    dm.movie_rank <= 10 
    AND (dm.keywords LIKE '%thriller%' OR dm.keywords IS NULL)
ORDER BY 
    dm.production_year DESC, 
    dm.actor_count DESC;
