
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS acting_order,
        COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS normalized_actor_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
),
MovieYearInfo AS (
    SELECT 
        m.production_year,
        COUNT(DISTINCT m.id) AS movie_count,
        AVG(CASE 
            WHEN m.production_year IS NULL THEN 0 
            ELSE m.production_year 
        END) AS avg_year
    FROM 
        aka_title m
    GROUP BY 
        m.production_year
),
FinalOutput AS (
    SELECT 
        ah.actor_name,
        mh.production_year,
        mh.movie_count,
        ah.movie_title,
        ah.acting_order,
        ROW_NUMBER() OVER (PARTITION BY ah.actor_name ORDER BY mh.movie_count DESC) AS actor_movie_rank
    FROM 
        ActorHierarchy ah
    LEFT JOIN 
        MovieYearInfo mh ON ah.nr_order = mh.movie_count
)
SELECT 
    f.actor_name,
    COALESCE(f.movie_title, 'No Movies Available') AS movie_title,
    f.production_year,
    COALESCE(f.movie_count, 0) AS movie_count,
    CASE 
        WHEN f.actor_movie_rank < 3 THEN 'Top Actor'
        ELSE 'Regular Actor'
    END AS actor_status
FROM 
    FinalOutput f
WHERE 
    (f.production_year IS NOT NULL AND f.movie_count > 10) OR 
    (f.production_year IS NULL AND f.actor_name LIKE 'A%')
ORDER BY 
    f.actor_movie_rank, f.movie_count DESC;
