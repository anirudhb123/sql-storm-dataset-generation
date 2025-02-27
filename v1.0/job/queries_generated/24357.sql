WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        SUM(COALESCE(mi.rating::numeric, 0)) AS total_rating,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_by_actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY SUM(COALESCE(mi.rating::numeric, 0)) DESC) AS rank_by_rating
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.id = ca.movie_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        total_rating,
        rank_by_actors,
        rank_by_rating
    FROM 
        RankedMovies
    WHERE 
        rank_by_actors <= 5 OR rank_by_rating <= 5
),
MovieStatistics AS (
    SELECT 
        actor_count,
        AVG(total_rating) AS avg_rating
    FROM 
        FilteredMovies
    GROUP BY 
        actor_count
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.total_rating,
    CASE 
        WHEN f.total_rating IS NULL THEN 'No Rating'
        WHEN f.total_rating > (SELECT AVG(total_rating) FROM FilteredMovies) THEN 'Above Average'
        ELSE 'Below Average'
    END AS rating_status,
    COALESCE(ms.avg_rating, 'None') AS avg_rating_for_actor_count
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieStatistics ms ON f.actor_count = ms.actor_count
ORDER BY 
    f.production_year DESC, 
    f.total_rating DESC, 
    f.actor_count;

