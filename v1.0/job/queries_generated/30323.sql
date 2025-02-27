WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        m.title,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title m ON mc.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
),
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY 
        ci.person_id
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(amc.movie_count, 0) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(amc.movie_count, 0) DESC) AS actor_rank
    FROM 
        aka_name a
    LEFT JOIN 
        actor_movie_count amc ON a.person_id = amc.person_id
)
SELECT 
    mh.movie_id,
    mh.title,
    ad.actor_id,
    ad.name AS actor_name,
    ad.movie_count,
    ad.actor_rank,
    COUNT(mh.movie_id) OVER (PARTITION BY mh.movie_id) AS total_cast_members
FROM 
    movie_hierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    actor_details ad ON ci.person_id = ad.actor_id
WHERE 
    ad.movie_count > 5
ORDER BY 
    mh.level, ad.actor_rank DESC;

This query performs several complex operations:

1. **Recursive CTE** `movie_hierarchy`: It builds a hierarchy of movies and their linked sequels/releases that came out after 2000.

2. **CTE** `actor_movie_count`: It counts the number of distinct movies for each actor using the `cast_info` table.

3. **CTE** `actor_details`: It retrieves the actor's details, including their name and the number of movies they've acted in, and ranks them based on the number of movies.

4. The **final SELECT** combines data from the `movie_hierarchy` and `actor_details`, joining with `cast_info`, filtering out actors with fewer than 5 movies and adding the total number of cast members using a window function.

The use of outer joins, window functions, recursive CTEs, and correlated subqueries makes this query particularly interesting for performance benchmarking in a complex data structure.
