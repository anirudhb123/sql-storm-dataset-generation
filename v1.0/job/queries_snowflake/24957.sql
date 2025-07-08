WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(ca.person_id) AS total_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.movie_id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = mt.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
SubQueryActors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name LIKE '%Steve%'
    GROUP BY 
        a.id, a.name
),
MoviesWithNoCast AS (
    SELECT 
        mt.movie_id,
        mt.title,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast,
        MAX(ci.note) AS last_note
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year < 2000
    GROUP BY 
        mt.movie_id, mt.title
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.year_rank,
    rm.total_cast,
    sa.actor_name,
    sa.movies_count,
    mn.title AS no_cast_title,
    mn.total_cast AS no_cast_total,
    mn.last_note AS no_cast_note
FROM 
    RankedMovies rm
LEFT JOIN 
    SubQueryActors sa ON rm.total_cast > sa.movies_count
FULL OUTER JOIN 
    MoviesWithNoCast mn ON rm.movie_id = mn.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC, sa.actor_name;
