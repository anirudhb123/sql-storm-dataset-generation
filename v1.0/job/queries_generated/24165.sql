WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        ci.person_id,
        ti.title,
        ti.production_year,
        ci.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY ti.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    WHERE 
        ti.production_year IS NOT NULL
),
role_summary AS (
    SELECT 
        ch.person_id,
        COUNT(*) AS movie_count,
        STRING_AGG(DISTINCT ch.title, ', ') AS titles,
        MAX(ch.production_year) AS last_movie_year
    FROM 
        cast_hierarchy ch
    GROUP BY 
        ch.person_id
),
detailed_roles AS (
    SELECT 
        ch.person_id,
        ch.title,
        ch.production_year,
        ch.cast_note,
        r.role AS role_description,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        cast_hierarchy ch
    JOIN 
        role_type r ON ch.cast_note = r.role
    LEFT JOIN 
        movie_keyword mk ON ch.production_year = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
all_cast_details AS (
    SELECT 
        dr.*, 
        COUNT(*) OVER (PARTITION BY dr.person_id) AS total_roles,
        COALESCE(p.gender, 'Not Specified') AS gender
    FROM 
        detailed_roles dr
    LEFT JOIN 
        name p ON dr.person_id = p.imdb_id
),
final_output AS (
    SELECT 
        r.person_id,
        r.gender,
        r.total_roles,
        r.titles,
        r.last_movie_year,
        COALESCE(r.role_description, 'No Role') AS role_description,
        CASE 
            WHEN r.production_year IS NOT NULL THEN r.production_year
            ELSE 'Unknown Year'
        END AS release_year,
        (CASE 
            WHEN r.gender = 'M' THEN 'He'
            WHEN r.gender = 'F' THEN 'She'
            ELSE 'They'
        END || ' appeared in ' || r.titles) AS narrative
    FROM 
        role_summary r
)

SELECT 
    f.person_id,
    f.gender,
    f.total_roles,
    f.titles,
    f.last_movie_year,
    f.role_description,
    f.release_year,
    f.narrative
FROM 
    final_output f
WHERE 
    f.total_roles > 1 
    AND f.last_movie_year > (SELECT AVG(last_movie_year) FROM role_summary)
ORDER BY 
    f.total_roles DESC, 
    f.last_movie_year DESC
LIMIT 10;

This query includes several advanced constructs:

- Recursive CTEs (`cast_hierarchy`) to gather a detailed list of cast members by their movie roles and productions.
- Aggregate functions with `STRING_AGG` to collect titles for each person.
- Window functions (`ROW_NUMBER()`, `COUNT() OVER`) to manage the order and counts of roles.
- Joins, including `LEFT JOIN`, to handle scenarios where keywords may be absent.
- Complex `CASE` statements to handle narrative construction.
- Filtering criteria that include conditions based on an average derived from subqueries, ensuring the selection is both dynamic and relevant for performance benchmarking.

This query aims to provide deeper insights into the contributions of actors in terms of their role diversity across films and integrates an engaging narrative presentation.
