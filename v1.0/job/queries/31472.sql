WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        movie_link.linked_movie_id,
        1 AS level
    FROM title
    LEFT JOIN movie_link ON title.id = movie_link.movie_id
    WHERE title.production_year > 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
    WHERE mh.level < 3  
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(*) OVER (PARTITION BY mh.movie_id) AS link_count
    FROM MovieHierarchy mh
),

PopularActors AS (
    SELECT 
        ci.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (SELECT movie_id FROM RankedMovies)
    GROUP BY ci.person_id, a.name
    HAVING COUNT(DISTINCT ci.movie_id) > 3
),

FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(pa.name, 'No actor') AS actor,
        rm.link_count
    FROM RankedMovies rm
    LEFT JOIN PopularActors pa ON rm.movie_id = pa.movies_count
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor,
    fr.link_count
FROM FinalResults fr
ORDER BY fr.link_count DESC, fr.production_year DESC
LIMIT 50;