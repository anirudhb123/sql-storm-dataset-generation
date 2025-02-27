WITH Actor_Movie_Role AS (
    SELECT 
        ak.name AS actor_name,
        m.title AS movie_title,
        r.role AS role_name,
        m.production_year AS year,
        c.nr_order AS cast_order
    FROM 
        cast_info c
    INNER JOIN 
        aka_name ak ON c.person_id = ak.person_id
    INNER JOIN 
        aka_title m ON c.movie_id = m.movie_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL 
        AND m.production_year BETWEEN 2000 AND 2023
),
Ranked_Actors AS (
    SELECT 
        actor_name,
        movie_title,
        year,
        role_name,
        cast_order,
        RANK() OVER (PARTITION BY movie_title ORDER BY cast_order) AS rank_within_movie
    FROM 
        Actor_Movie_Role
),
Movies_With_Keyword AS (
    SELECT 
        m.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title m
    INNER JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
        AND m.production_year BETWEEN 2000 AND 2023
),
Actor_Keyword_Join AS (
    SELECT 
        ra.actor_name,
        ra.movie_title,
        ra.year,
        ra.role_name,
        rwk.keyword
    FROM 
        Ranked_Actors ra
    INNER JOIN 
        Movies_With_Keyword rwk ON ra.movie_title = rwk.movie_title
    WHERE 
        ra.rank_within_movie <= 5  -- Only select top 5 actors in casting order
)
SELECT 
    ak.actor_name,
    ak.movie_title,
    ak.year,
    ak.role_name,
    COUNT(DISTINCT ak.keyword) AS keyword_count
FROM 
    Actor_Keyword_Join ak
GROUP BY 
    ak.actor_name, ak.movie_title, ak.year, ak.role_name
ORDER BY 
    ak.year DESC, keyword_count DESC;
