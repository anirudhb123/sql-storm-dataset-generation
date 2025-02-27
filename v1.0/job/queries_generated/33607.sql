WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        CAST(NULL AS integer) AS parent_movie_id,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS mh ON e.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    rm.production_year,
    c.cast_count,
    COALESCE(c.cast_names, 'No Cast') AS cast_names,
    CASE 
        WHEN mh.level = 1 THEN 'Main Movie'
        ELSE 'Episode ' || mh.level
    END AS movie_type
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    ranked_movies AS rm ON mh.movie_id = rm.id
LEFT JOIN 
    cast_info_summary AS c ON mh.movie_id = c.movie_id
WHERE 
    rm.title_rank <= 5
ORDER BY 
    mh.level, rm.production_year DESC;

This SQL query demonstrates the following concepts:

1. **Common Table Expressions (CTEs)**: Utilizes a recursive CTE (`movie_hierarchy`) to build a hierarchy of movies and their episodes.
2. **Window Functions**: Implements `ROW_NUMBER()` to generate a rank for movies by their title within each production year.
3. **Aggregate Functions**: Uses `COUNT()` and `STRING_AGG()` to summarize cast information.
4. **Outer Joins**: Applies `LEFT JOIN` to get potentially missing cast data gracefully.
5. **Complicated predicates**: Includes checks for movie levels and ranks to filter the final output.
6. **String Expressions**: Concatenates strings within the `CASE` statement to create descriptive movie types.
7. **NULL Logic**: Uses `COALESCE()` to handle cases where there might not be any cast data.
