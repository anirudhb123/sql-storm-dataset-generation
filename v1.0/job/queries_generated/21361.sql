WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
RankedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rn,
        mh.depth
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        depth
    FROM 
        RankedMovies
    WHERE 
        (depth = 1 AND rn <= 10) OR (depth > 1 AND rn <= 5)
),
ActorFilmography AS (
    SELECT 
        ak.name AS actor_name,
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    JOIN 
        aka_title at ON cc.movie_id = at.id
    GROUP BY 
        ak.name, at.title, at.production_year
),
ActorSummary AS (
    SELECT 
        actor_name,
        STRING_AGG(title || ' (' || production_year || ')', ', ') AS films
    FROM 
        ActorFilmography
    GROUP BY 
        actor_name
)
SELECT 
    fm.title AS movie_title,
    fm.production_year,
    asum.actor_name,
    asum.films AS actor_films,
    COALESCE(NULLIF(fm.title, ''), 'Untitled Movie') AS final_title,
    CASE 
        WHEN fm.production_year IS NOT NULL THEN 'Released'
        ELSE 'Pending'
    END AS release_status
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorSummary asum ON asum.films LIKE '%' || fm.title || '%'
WHERE 
    fm.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
ORDER BY 
    fm.production_year, fm.title;
