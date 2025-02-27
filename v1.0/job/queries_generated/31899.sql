WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        CASE 
            WHEN t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') THEN 'Feature Film'
            WHEN t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'series') THEN 'Series'
            ELSE 'Other'
        END AS movie_type,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.movie_type,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        mh.level < 5
),
Actors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.movie_type,
        a.actor_name,
        a.actor_rank,
        COALESCE(mo.info, 'No Info Available') AS more_info
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        Actors a ON mh.movie_id = a.movie_id
    LEFT JOIN 
        movie_info mo ON mh.movie_id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    md.title,
    md.production_year,
    md.movie_type,
    STRING_AGG(DISTINCT md.actor_name, ', ' ORDER BY md.actor_rank) AS actors,
    COUNT(DISTINCT md.movie_id) OVER (PARTITION BY md.movie_type) AS total_movies_of_type,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Not Specified'
        ELSE md.production_year::text 
    END AS year_info
FROM 
    MovieDetails md
WHERE 
    md.actor_rank <= 3 OR md.actor_rank IS NULL
GROUP BY 
    md.movie_id, md.title, md.production_year, md.movie_type
ORDER BY 
    md.production_year DESC, 
    md.title;
