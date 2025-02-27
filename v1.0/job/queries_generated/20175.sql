WITH MovieStats AS (
    SELECT 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year, 
        COUNT(DISTINCT ci.person_id) AS co_actors_count,
        AVG(COALESCE(CAST(mi.info AS INT), 0)) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        a.name IS NOT NULL 
        AND t.production_year IS NOT NULL 
        AND t.production_year > 2000 
        AND t.title LIKE 'A%'
    GROUP BY 
        a.id, t.title, t.production_year 
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), ActorRank AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year, 
        co_actors_count, 
        avg_rating,
        recent_movie_rank,
        DENSE_RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank
    FROM 
        MovieStats
), MoviesWithCompensation AS (
    SELECT 
        ar.actor_name, 
        ar.movie_title, 
        ar.production_year, 
        ar.co_actors_count, 
        ar.avg_rating,
        ar.rating_rank,
        CASE 
            WHEN ar.avg_rating IS NULL THEN 'No Rating' 
            WHEN ar.avg_rating < 5 THEN 'Below Average' 
            ELSE 'Above Average' 
        END AS rating_category
    FROM 
        ActorRank ar
)
SELECT 
    mwc.actor_name,
    mwc.movie_title,
    mwc.production_year,
    mwc.co_actors_count,
    mwc.avg_rating,
    mwc.rating_rank,
    mwc.rating_category,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ')
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = (
            SELECT id FROM aka_title WHERE title = mwc.movie_title AND production_year = mwc.production_year LIMIT 1
        )), 'No Keywords') AS keywords
FROM 
    MoviesWithCompensation mwc
WHERE 
    mwc.rating_category = 'Above Average' 
    OR mwc.co_actors_count > 10
ORDER BY 
    mwc.rating_rank, mwc.co_actors_count DESC;

