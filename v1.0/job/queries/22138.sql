WITH RecursiveCTE AS (
    SELECT 
        ct.person_id,
        ct.movie_id,
        rn.role,
        ROW_NUMBER() OVER (PARTITION BY ct.movie_id ORDER BY ct.nr_order) AS role_rank
    FROM 
        cast_info ct
    JOIN 
        role_type rn ON ct.role_id = rn.id
),
FilteredRoles AS (
    SELECT 
        r.person_id,
        r.movie_id,
        r.role,
        r.role_rank,
        ak.name AS actor_name,
        m.title AS movie_title,
        m.production_year
    FROM 
        RecursiveCTE r
    JOIN 
        aka_name ak ON r.person_id = ak.person_id
    JOIN 
        aka_title m ON r.movie_id = m.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020 
        AND ak.name IS NOT NULL
        AND r.role_rank <= 3
),
MovieDetails AS (
    SELECT 
        movie_id,
        COUNT(*) AS num_actors,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors_list
    FROM 
        FilteredRoles
    GROUP BY 
        movie_id
),
ComprehensiveInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(md.num_actors, 0) AS actor_count,
        COALESCE(md.actors_list, 'No Actors') AS actors,
        CASE 
            WHEN m.production_year % 2 = 0 THEN 'Even Year'
            ELSE 'Odd Year'
        END AS year_type
    FROM 
        aka_title m
    LEFT JOIN 
        MovieDetails md ON m.movie_id = md.movie_id
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    COUNT(*) AS total_movies,
    AVG(actor_count) AS average_actors_per_movie,
    MAX(actor_count) AS max_actors_in_a_movie,
    MIN(actor_count) AS min_actors_in_a_movie,
    year_type
FROM 
    ComprehensiveInfo
GROUP BY 
    year_type
ORDER BY 
    year_type DESC;
