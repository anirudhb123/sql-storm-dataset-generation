WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, COUNT(ki.keyword) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
average_year AS (
    SELECT 
        AVG(m.production_year) AS avg_prod_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
performance_benchmark AS (
    SELECT 
        ak.name,
        mt.title,
        mt.production_year,
        rk.rank,
        CASE 
            WHEN rk.rank = 1 THEN 'Top Movie'
            ELSE 'Other Movie'
        END AS movie_classification,
        COALESCE(pi.info, 'No Info') AS person_info,
        COUNT(ci.id) OVER (PARTITION BY ak.person_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        ranked_movies rk ON ci.movie_id = rk.movie_id
    JOIN 
        aka_title mt ON rk.movie_id = mt.id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id 
        AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    WHERE 
        mt.production_year > (SELECT avg_prod_year FROM average_year)
)
SELECT 
    *,
    CASE 
        WHEN movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Occasional Actor'
    END AS actor_type
FROM 
    performance_benchmark
WHERE 
    movie_classification = 'Top Movie'
ORDER BY 
    mt.production_year DESC, 
    ak.name
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;

This query performs the following tasks:

1. **Using CTEs**: It defines multiple Common Table Expressions (CTEs) for organizing data.
2. **Ranking Movies**: `ranked_movies` CTE ranks movies by production year and counts keywords associated with them.
3. **Average Year Calculation**: The `average_year` CTE computes the average production year of all movies to filter out older productions later.
4. **Joining and Data Enrichment**: In the `performance_benchmark`, it combines data from various tables, providing person info and counting movies per actor.
5. **Dynamic Classification**: The query creates conditions that dynamically classify the movie and actor based on the results.
6. **NULL Handling**: Uses COALESCE to handle NULL values in person info gracefully.
7. **Advanced Filtering and Ordering**: It filters results belonging to only top-ranked movies and orders them while implementing pagination.

This setup exemplifies intricate SQL constructs and subtly addresses specific corner cases in data querying.
