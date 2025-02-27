
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        r.role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
AggregatedRoles AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS cast_names,
        COUNT(*) AS total_actors
    FROM 
        RankedMovies
    GROUP BY 
        movie_id, movie_title, production_year
),
DetailedInfo AS (
    SELECT 
        am.movie_id,
        am.movie_title,
        am.production_year,
        am.cast_names,
        am.total_actors,
        STRING_AGG(mi.info, '; ') AS movie_infos
    FROM 
        AggregatedRoles am
    LEFT JOIN 
        movie_info mi ON am.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Genre%' OR info LIKE '%Synopsis%')
    GROUP BY 
        am.movie_id, am.movie_title, am.production_year, am.cast_names, am.total_actors
)
SELECT 
    d.movie_id,
    d.movie_title,
    d.production_year,
    d.cast_names,
    d.total_actors,
    d.movie_infos
FROM 
    DetailedInfo d
WHERE 
    d.total_actors > 5
ORDER BY 
    d.production_year DESC, d.movie_title;
