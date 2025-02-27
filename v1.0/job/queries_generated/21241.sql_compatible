
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(ci.person_id) OVER (PARTITION BY at.id) AS total_actors,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY at.id) AS has_notes_avg
    FROM 
        aka_title AS at
    LEFT JOIN 
        cast_info AS ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year > 2000
        AND (ak.name IS NOT NULL AND ak.name <> '')
        AND (ci.note IS NULL OR ci.note <> '')
), 
MovieStats AS (
    SELECT 
        production_year,
        COUNT(*) AS movies_count,
        AVG(total_actors) AS avg_actors_per_movie,
        MAX(year_rank) AS highest_rank
    FROM 
        RankedMovies
    GROUP BY 
        production_year
),
NotableYears AS (
    SELECT 
        production_year,
        movies_count,
        avg_actors_per_movie,
        highest_rank,
        CASE 
            WHEN movies_count >= (SELECT AVG(movies_count) FROM MovieStats) THEN 'Popular'
            ELSE 'Less Popular'
        END AS popularity
    FROM 
        MovieStats
    WHERE 
        highest_rank > 1 AND avg_actors_per_movie IS NOT NULL
)

SELECT 
    ny.production_year, 
    ny.movies_count, 
    ny.avg_actors_per_movie, 
    ny.popularity,
    STRING_AGG(DISTINCT nm.name, ', ') AS notable_actors
FROM 
    NotableYears AS ny
LEFT JOIN 
    aka_title AS at ON at.production_year = ny.production_year
LEFT JOIN 
    cast_info AS ci ON at.id = ci.movie_id
LEFT JOIN 
    aka_name AS nm ON ci.person_id = nm.person_id
WHERE 
    ny.movies_count > 1 
GROUP BY 
    ny.production_year, ny.movies_count, ny.avg_actors_per_movie, ny.popularity
ORDER BY 
    ny.production_year DESC;
