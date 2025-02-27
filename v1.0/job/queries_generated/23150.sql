WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')  -- Considering only movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        l.title AS title,
        l.production_year,
        mh.title_path || l.title AS title_path
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title l ON ml.linked_movie_id = l.id
    WHERE 
        l.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredActors AS (
    SELECT 
        ak.person_id,
        ak.id AS aka_id,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_name ak
    WHERE 
        ak.name LIKE '%Smith%'  -- Filtering actors by a specific surname
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) as cast_order,
        p.gender AS actor_gender
    FROM 
        cast_info ci
    JOIN 
        FilteredActors fa ON ci.person_id = fa.person_id
    LEFT JOIN 
        name p ON fa.person_id = p.imdb_id -- This assumes imdb_id in name corresponds to person_id
),
MovieStatistics AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(DISTINCT cd.person_id) AS total_actors,
        COUNT(DISTINCT cd.actor_gender) FILTER (WHERE cd.actor_gender IS NOT NULL) AS unique_genders,  -- Counting unique genders
        STRING_AGG(DISTINCT cd.actor_gender, ', ') AS genders_list,
        MAX(cd.cast_order) AS max_order,
        MIN(cd.cast_order) AS min_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.title, mh.production_year
)
SELECT 
    ms.title, 
    ms.production_year,
    ms.total_actors,
    ms.unique_genders,
    ms.genders_list,
    CASE 
        WHEN ms.total_actors > 0 THEN (ms.max_order - ms.min_order + 1) 
        ELSE NULL 
    END AS rank_range,
    CASE 
        WHEN ms.unique_genders > 0 THEN ROUND((ms.total_actors::numeric / ms.unique_genders)::numeric, 2) 
        ELSE NULL 
    END AS actors_per_gender_ratio
FROM 
    MovieStatistics ms
WHERE 
    ms.production_year BETWEEN 1990 AND 2020  -- Filtering by production year
ORDER BY 
    ms.production_year DESC,
    ms.total_actors DESC
LIMIT 10;

