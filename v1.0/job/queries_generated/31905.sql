WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
),
ActorMovieCount AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    JOIN
        aka_title a ON ci.movie_id = a.id
    WHERE
        a.production_year >= 2000
    GROUP BY
        ci.person_id
),
TopActors AS (
    SELECT
        a.id AS actor_id,
        ak.name AS actor_name,
        ac.movie_count
    FROM
        ActorMovieCount ac
    JOIN
        aka_name ak ON ac.person_id = ak.person_id
    WHERE
        ac.movie_count > 3
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(a.actor_name, ', ') AS cast_names,
        COUNT(DISTINCT mw.id) AS keyword_count,
        SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mw ON mh.movie_id = mw.movie_id
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        TopActors a ON ci.person_id = a.actor_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_names,
    ms.keyword_count,
    ms.info_count
FROM 
    MovieStats ms
WHERE 
    ms.info_count > 2
ORDER BY 
    ms.production_year DESC, ms.keyword_count DESC;
