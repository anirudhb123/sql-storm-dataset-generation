
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS level
    FROM
        aka_title t
        JOIN movie_companies mc ON t.id = mc.movie_id
        JOIN company_name c ON mc.company_id = c.id
        JOIN aka_name a ON c.imdb_id = a.person_id
        JOIN title m ON t.id = m.id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        mh.movie_id,
        t.title,
        m.production_year,
        level + 1
    FROM
        MovieHierarchy mh
        JOIN movie_link ml ON mh.movie_id = ml.movie_id
        JOIN aka_title t ON ml.linked_movie_id = t.id
        JOIN title m ON t.id = m.id
    WHERE
        mh.level < 3
),
AggregatedInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT ci.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        MovieHierarchy m
        LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
        LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
        LEFT JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.movie_id
),
FinalOutput AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ai.cast_count,
        ai.actor_names
    FROM 
        MovieHierarchy mh
        LEFT JOIN AggregatedInfo ai ON mh.movie_id = ai.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(f.cast_count, 0) AS total_cast,
    COALESCE(f.actor_names, 'No cast available') AS actors_list
FROM 
    FinalOutput f
ORDER BY 
    f.production_year DESC,
    f.title ASC;
