WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.kind_id DESC) AS rank_per_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id
),

co_star_appearances AS (
    SELECT 
        ci1.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci2.person_id) AS co_stars_count
    FROM 
        cast_info ci1
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN 
        aka_name a ON ci1.person_id = a.person_id
    GROUP BY 
        ci1.movie_id, a.name
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.rank_per_year,
    COALESCE(ca.co_stars_count, 0) AS total_co_stars,
    CASE 
        WHEN rm.cast_count > 10 THEN 'BLOCKBUSTER'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS size_category,
    STRING_AGG(DISTINCT ca.actor_name, ', ') AS co_star_names
FROM 
    ranked_movies rm
LEFT JOIN 
    co_star_appearances ca ON rm.movie_id = ca.movie_id
WHERE 
    rm.rank_per_year <= 5 AND (rm.production_year IS NOT NULL OR rm.production_year >= 2000)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rm.rank_per_year, rm.cast_count
HAVING 
    SUM(CASE WHEN ca.co_stars_count IS NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    rm.production_year DESC, size_category;

This SQL query defines two Common Table Expressions (CTEs): `ranked_movies` and `co_star_appearances`. The main query retrieves movie titles along with their production year, the rank of the movie for that year, the number of co-stars in each film, and categorizes the movie size based on the cast count. 

It incorporates several SQL constructs, including:

- CTEs for intermediate calculations.
- SUM and COUNT aggregation functions.
- Row numbering with the `ROW_NUMBER` window function.
- Conditional aggregation and size categorization through `CASE`.
- Stringagg to combine actor names.
- Compound WHERE clause with IS NOT NULL and comparisons.
- Outer joins to ensure we still show movies without co-stars.
- A HAVING clause to filter based on counts of null co-stars. 

Overall, it captures a complex relationship between movies and their casts while ensuring performance through indexed joins.
