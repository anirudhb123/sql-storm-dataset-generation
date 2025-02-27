WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select top-level movies (no parent)
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL AS parent_id,
        1 AS level
    FROM
        title t
    WHERE
        t.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Select episodes of movies
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM
        title t
    JOIN
        movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),

-- Join movie information and cast details
movie_details AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COALESCE(c.kind, 'Not Provided') AS cast_type,
        COUNT(DISTINCT mi.info) AS info_count
    FROM
        movie_hierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        comp_cast_type c ON ci.role_id = c.id
    LEFT JOIN
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, a.name, c.kind
)

-- Final selection with window functions and filtering
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.cast_type,
    md.info_count,
    RANK() OVER (PARTITION BY md.production_year ORDER BY md.info_count DESC) as rank_by_info_count,
    CASE 
        WHEN md.info_count IS NULL THEN 'No Info'
        ELSE 'Has Info'
    END AS info_status
FROM
    movie_details md
WHERE
    md.production_year > 2000
ORDER BY
    md.production_year DESC,
    info_count DESC;

This query performs the following operations: 

1. A recursive CTE (`movie_hierarchy`) is created to capture both main movies and their episodes.
2. It constructs a second CTE (`movie_details`) that gathers related movie information and counts how many distinct info entries exist for each movie.
3. It utilizes window functions to rank movies based on the number of info entries they have.
4. A filtering step is applied to select movies produced after the year 2000.
5. The final output includes movie details alongside computed fields indicating the rank and info status.
