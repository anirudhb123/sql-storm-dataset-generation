WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        mh.level + 1
    FROM 
        movie_link ml 
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id 
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order,
        COALESCE(ci.note, 'No Note') AS actor_note 
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id 
    WHERE 
        ak.name IS NOT NULL
),
MovieGenres AS (
    SELECT DISTINCT
        mt.movie_id,
        kt.keyword AS genre
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT ma.actor_name) AS actor_count,
        STRING_AGG(DISTINCT mg.genre, ', ') AS genres,
        RANK() OVER (ORDER BY COUNT(DISTINCT ma.actor_name) DESC) AS rank_by_actors,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ma.actor_name) DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieActors ma ON mh.movie_id = ma.movie_id
    LEFT JOIN 
        MovieGenres mg ON mh.movie_id = mg.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
)
SELECT 
    rm.rank_by_actors,
    rm.rank_within_year,
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    COALESCE(rm.genres, 'No Genres') AS genres
FROM 
    RankedMovies rm
WHERE 
    rm.actor_count > 0 
ORDER BY 
    rm.rank_by_actors, rm.production_year DESC;
