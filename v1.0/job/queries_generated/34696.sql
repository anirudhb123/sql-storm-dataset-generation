WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
),
RankedActors AS (
    SELECT 
        ka.name AS actor_name,
        ka.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.name, ka.person_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        AVG(rank.actor_rank) AS avg_actor_rank
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    JOIN 
        RankedActors rank ON ci.person_id = rank.person_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
),
FinalResults AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        COALESCE(tm.total_actors, 0) AS total_actors,
        COALESCE(tm.avg_actor_rank, 0.0) AS avg_actor_rank,
        COALESCE(ki.keyword, 'No Keywords') AS keyword
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        tm.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.total_actors,
    fr.avg_actor_rank,
    ARRAY_AGG(DISTINCT fr.keyword) AS keywords
FROM 
    FinalResults fr
GROUP BY 
    fr.movie_title, fr.production_year, fr.total_actors, fr.avg_actor_rank
ORDER BY 
    fr.avg_actor_rank DESC, fr.total_actors DESC
LIMIT 10;
