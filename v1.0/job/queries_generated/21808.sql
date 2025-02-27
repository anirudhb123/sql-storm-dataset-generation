WITH ranked_movies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS cast_rank,
        COUNT(DISTINCT d.person_id) OVER (PARTITION BY a.id) AS total_cast,
        COALESCE(e.note, 'No Note') AS company_note,
        f.info AS movie_info
    FROM
        aka_title a
    LEFT JOIN
        cast_info b ON a.id = b.movie_id
    LEFT JOIN
        movie_companies c ON a.id = c.movie_id
    LEFT JOIN
        company_name e ON c.company_id = e.id
    LEFT JOIN
        movie_info f ON a.id = f.movie_id
    WHERE 
        a.production_year > 2000
        AND e.country_code IS NOT NULL
        AND (e.name LIKE '%Studios%' OR e.name LIKE '%Production%')
),
filtered_movies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_rank,
        movie_info
    FROM 
        ranked_movies
    WHERE 
        cast_rank <= 5
    UNION ALL
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_rank,
        NULL AS movie_info
    FROM 
        ranked_movies
    WHERE 
        cast_rank > 5 AND total_cast > 10
),
combined_info AS (
    SELECT
        title.movie_title,
        title.production_year,
        title.total_cast,
        title.cast_rank,
        (title.movie_info || ' | ' || COALESCE(genre.kind, 'Unknown')) AS final_info
    FROM 
        filtered_movies title
    LEFT JOIN
        kind_type genre ON title.production_year % 5 = genre.id
)
SELECT
    movie_title,
    production_year,
    total_cast,
    cast_rank,
    CASE
        WHEN final_info IS NULL THEN 'Info not available'
        WHEN total_cast > 20 THEN 'Blockbuster'
        ELSE final_info
    END AS processed_info
FROM 
    combined_info
WHERE
    (processed_info NOT LIKE '%No Note%' OR processed_info NOT LIKE '%Info not available%')
ORDER BY 
    production_year DESC, 
    total_cast DESC;
