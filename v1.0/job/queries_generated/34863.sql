WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

ActorRatings AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS average_positive_reviews
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Reviews')
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
)

SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    ar.actor_name,
    ar.movie_count,
    ar.average_positive_reviews
FROM 
    RankedMovies rm
JOIN 
    ActorRatings ar ON rm.movie_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.person_id = (
                SELECT 
                    ak.person_id 
                FROM 
                    aka_name ak 
                WHERE 
                    ak.name = ar.actor_name
            )
    )
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    ar.average_positive_reviews DESC;

-- This query retrieves the top 5 movies per year since 2000 based on the total cast. 
-- It also fetches each actor's contribution in terms of the number of movies they've acted in 
-- and their average positive reviews (if any).
-- The use of recursive CTEs signifies the potential for nested movie relationships (e.g., sequels, prequels).
