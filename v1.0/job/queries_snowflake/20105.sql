WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS year_rank,
        COUNT(*) OVER (PARTITION BY a.production_year) AS movie_count
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'film%')
),
FilteredActors AS (
    SELECT 
        c.person_id,
        c.movie_id,
        p.gender,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.id
    WHERE 
        p.gender IS NOT NULL
),
ActorPerformance AS (
    SELECT 
        f.movie_id,
        COUNT(DISTINCT f.person_id) AS total_actors,
        SUM(CASE WHEN f.gender = 'F' THEN 1 ELSE 0 END) AS female_actors,
        SUM(CASE WHEN f.gender = 'M' THEN 1 ELSE 0 END) AS male_actors
    FROM 
        FilteredActors f
    GROUP BY 
        f.movie_id
)
SELECT 
    m.movie_id,
    m.movie_title,
    m.production_year,
    COALESCE(a.total_actors, 0) AS actor_count,
    COALESCE(a.female_actors, 0) AS female_actor_count,
    COALESCE(a.male_actors, 0) AS male_actor_count,
    CASE 
        WHEN m.movie_count > 5 THEN 'Highly Produced'
        WHEN m.movie_count BETWEEN 3 AND 5 THEN 'Moderately Produced'
        ELSE 'Low Produced' 
    END AS production_category
FROM 
    RankedMovies m
LEFT JOIN 
    ActorPerformance a ON m.movie_id = a.movie_id
WHERE 
    m.year_rank <= 3 OR m.year_rank IS NULL
ORDER BY 
    m.production_year DESC,
    a.total_actors DESC NULLS LAST,
    m.movie_title;

