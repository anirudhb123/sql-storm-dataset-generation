WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        t.title,
        COALESCE(m.title, 'N/A') AS linked_title,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY m.release_year DESC NULLS LAST) AS rank
    FROM
        aka_title t
    LEFT JOIN
        movie_link ml ON t.movie_id = ml.movie_id
    LEFT JOIN
        aka_title m ON ml.linked_movie_id = m.movie_id
    WHERE
        t.production_year IS NOT NULL
), 
FilteredActors AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count,
        AVG(CASE WHEN pi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY ci.movie_id) AS average_info_provided
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        person_info pi ON ci.person_id = pi.person_id
    WHERE
        ak.name IS NOT NULL
),
MovieStatistics AS (
    SELECT 
        rm.movie_id,
        rm.title,
        COUNT(DISTINCT fa.actor_name) AS total_actors,
        MAX(fa.actor_count) AS max_actors_in_a_single_movie,
        SUM(fa.average_info_provided) AS total_info_provided
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredActors fa ON rm.movie_id = fa.movie_id
    GROUP BY 
        rm.movie_id, rm.title
    HAVING 
        COUNT(DISTINCT fa.actor_name) > 1
)
SELECT 
    ms.title,
    CASE 
        WHEN ms.total_actors > 5 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    ms.max_actors_in_a_single_movie AS peak_cast_size,
    COALESCE(ms.total_info_provided, 0) AS total_info_count,
    COALESCE(AVG(NULLIF(ms.total_info_provided, 0)), 0) AS average_info_provided_per_movie
FROM 
    MovieStatistics ms
WHERE 
    ms.total_actors > 2 AND ms.total_info_provided IS NOT NULL
ORDER BY 
    ms.total_actors DESC, ms.title;
