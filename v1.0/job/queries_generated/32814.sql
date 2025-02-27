WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        c.nr_order = 1  -- Start with principal roles

    UNION ALL

    SELECT
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ah.level + 1
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        Movie_Info mi ON c.movie_id = mi.movie_id
    JOIN
        ActorHierarchy ah ON ah.cast_id = mi.movie_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        c.nr_order > 1  -- Recursive join to find co-stars
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY
        m.movie_id
)
SELECT 
    ah.actor_name,
    ah.movie_title,
    ah.production_year,
    mk.keywords,
    COUNT(DISTINCT ah.cast_id) OVER (PARTITION BY ah.actor_name) AS total_movies,
    CASE 
        WHEN ah.production_year > 2000 THEN 'Modern Era' 
        ELSE 'Classic' 
    END AS era,
    CASE 
        WHEN mk.keywords IS NULL THEN 'No Keywords' 
        ELSE mk.keywords 
    END AS keywords_summary
FROM
    ActorHierarchy ah
LEFT JOIN 
    MovieKeywords mk ON ah.movie_title = mk.movie_id
WHERE 
    ah.level = 1  -- Filter for primary roles
ORDER BY 
    total_movies DESC, 
    ah.actor_name;

This SQL query aims to benchmark performance by showcasing complex SQL constructs:
- Recursive Common Table Expressions (CTEs) are used to build an actor hierarchy based on casting.
- Aggregation with `STRING_AGG` is leveraged to provide a comma-separated list of keywords associated with each movie.
- Window functions are applied to calculate the total number of movies per actor.
- Case statements are used to classify movies into two eras based on their production year.
- Left joins help in including movies that might not have keywords, demonstrating NULL logic. 

This structure creates an intricate yet informative data retrieval that can be useful in benchmarking SQL performance against the specified schema.
