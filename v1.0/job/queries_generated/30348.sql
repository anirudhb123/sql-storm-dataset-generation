WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select all movies with their titles and years
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.linked_movie_id AS parent_movie_id
    FROM 
        title t
    LEFT JOIN 
        movie_link m ON t.id = m.movie_id

    UNION ALL

    -- Recursive case: Join the movies linked to the previously selected movies
    SELECT 
        t.id,
        t.title,
        t.production_year,
        m.linked_movie_id AS parent_movie_id
    FROM 
        title t
    JOIN 
        movie_link m ON t.id = m.movie_id
    INNER JOIN 
        movie_hierarchy mh ON mh.parent_movie_id = t.id
), 
movie_cast AS (
    -- Cast info with window function to rank actors based on their roles in movies
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
), 
movie_keywords AS (
    -- Collect all keywords for each movie
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_combined AS (
    -- Combine movie info types for each movie
    SELECT 
        mi.movie_id,
        STRING_AGG(CONCAT(it.info, ': ', mi.info), '; ') AS info_combined
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

-- Final selection
SELECT 
    th.title,
    th.production_year,
    mc.actor_name,
    mc.actor_rank,
    mk.keywords,
    mic.info_combined,
    CASE 
        WHEN th.production_year IS NULL THEN 'Year Not Available'
        ELSE CAST(th.production_year AS VARCHAR)
    END AS production_year_display
FROM 
    movie_hierarchy th
LEFT JOIN 
    movie_cast mc ON th.movie_id = mc.movie_id
LEFT JOIN 
    movie_keywords mk ON th.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_combined mic ON th.movie_id = mic.movie_id
WHERE 
    th.title IS NOT NULL
ORDER BY 
    th.production_year DESC, 
    mc.actor_rank ASC;

This SQL query accomplishes the following:

1. **Recursive CTE**: It constructs a hierarchy of movies that are linked to each other, useful for exploring sequels or related films.
2. **Window Functions**: It ranks actors within each movie based on their appearance order captured in `cast_info`.
3. **String Aggregation**: It combines keywords and movie information into single strings for easier readability.
4. **NULL Handling**: It includes logic to handle NULL values specifically for production years.
5. **Comprehensive Output**: It outputs a detailed list combining titles, their production years, a ranked roster of actors, keywords, and other relevant movie information while organizing results for visibility.
