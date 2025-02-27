WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
    FROM 
        MovieHierarchy mh
),
ActorBonus AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(n.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(ab.actor_count, 0) AS actor_count,
        ab.actors,
        RANK() OVER (ORDER BY COALESCE(ab.actor_count, 0) DESC) AS actor_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        ActorBonus ab ON mt.id = ab.movie_id
),
FinalResults AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count,
        m.actors,
        r.title_rank,
        CASE 
            WHEN m.actor_count > 5 THEN 'Blockbuster'
            ELSE 'Indie'
        END AS movie_type
    FROM 
        MovieInfo m
    JOIN 
        RankedMovies r ON m.movie_id = r.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.actors,
    fr.title_rank,
    fr.movie_type
FROM 
    FinalResults fr
WHERE 
    fr.production_year >= 2000
ORDER BY 
    fr.actor_rank, fr.title;
