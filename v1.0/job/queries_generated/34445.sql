WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level 
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title AS t
    JOIN MovieHierarchy AS mh ON t.episode_of_id = mh.movie_id
), MovieStats AS (
    SELECT 
        m.production_year,
        COUNT(DISTINCT m.movie_id) AS movie_count,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN i.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
        MAX(m.production_year) AS latest_year,
        MIN(m.production_year) AS earliest_year
    FROM 
        MovieHierarchy AS m
    LEFT JOIN 
        cast_info AS c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_info AS i ON m.movie_id = i.movie_id
    GROUP BY 
        m.production_year
)
SELECT 
    ms.production_year,
    ms.movie_count,
    ms.cast_count,
    ms.info_count,
    CASE 
        WHEN ms.latest_year IS NOT NULL THEN ms.latest_year 
        ELSE 'No Movies' 
    END AS latest_release,
    CASE 
        WHEN ms.earliest_year IS NOT NULL THEN ms.earliest_year 
        ELSE 'No Movies' 
    END AS oldest_release
FROM 
    MovieStats AS ms
ORDER BY 
    ms.production_year DESC
LIMIT 10;

This query creates a recursive Common Table Expression (CTE) named `MovieHierarchy` to build a hierarchy of movies (including episodes) based on potentially complex relationships. It also calculates various statistics regarding movies by year in the `MovieStats` CTE. The final SELECT retrieves and formats information about the number of movies produced, the number of casts involved, and relevant release years, handling potential NULLs gracefully with case expressions. The results are ordered by production year, limiting the output to the most recent ten years.
