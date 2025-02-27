WITH RECURSIVE employee_hierarchy AS (
    SELECT 
        person_id,
        name,
        0 AS level
    FROM 
        aka_name
    WHERE 
        person_id IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        a.name,
        eh.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        employee_hierarchy eh ON eh.person_id = c.person_id
    WHERE 
        c.nr_order = 1
),

movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS cast_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        RANK() OVER (PARTITION BY md.production_year ORDER BY COUNT(cast_names) DESC) AS rank
    FROM 
        movie_details md
    JOIN 
        movie_keyword mk ON mk.movie_id = md.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year
    HAVING 
        COUNT(mk.keyword_id) > 0
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.rank,
    COALESCE(cast_names, 'No Cast') AS cast_names,
    COALESCE(NULLIF(cast_names, ''), 'Unknown') AS cast_names_nullcheck
FROM 
    ranked_movies r
LEFT JOIN 
    movie_details md ON md.movie_id = r.movie_id
WHERE 
    r.rank <= 10
ORDER BY 
    r.production_year DESC, 
    r.rank;

-- Further analysis of the top 10 movies with the longest titles and their cast.
SELECT 
    title,
    LENGTH(title) AS title_length,
    ARRAY_AGG(cast_info.name ORDER BY cast_info.name) AS cast_names
FROM 
    aka_title
LEFT JOIN 
    cast_info ON cast_info.movie_id = aka_title.id
LEFT JOIN 
    aka_name ON aka_name.person_id = cast_info.person_id
WHERE 
    LENGTH(title) > 20
GROUP BY 
    title
ORDER BY 
    title_length DESC
LIMIT 10;

This SQL query includes several constructs:

- **Recursive CTE**: `employee_hierarchy` builds an employee hierarchy based on roles.
- **Window function**: `RANK()` is used to rank movies based on the number of cast names.
- **Outer join**: `LEFT JOIN` is used to ensure that all movies are included in the final output, even if they have no cast.
- **Set operators**: The use of `ARRAY_AGG` to combine cast names into a single array for concise output.
- **Complicated predicates**: Includes various filters such as year restrictions and title length checks.
- **NULL handling**: `COALESCE` and `NULLIF` functions ensure proper handling of NULL values in the output.

The query is structured to first gather movie details, then rank them, and finally end with the top results along with further movie title analysis.
