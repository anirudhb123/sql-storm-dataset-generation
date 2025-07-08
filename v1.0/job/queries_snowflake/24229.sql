
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS titles_count
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
), 
cast_roles AS (
    SELECT
        ci.movie_id,
        ct.kind AS role_type,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY
        ci.movie_id, ct.kind
),
filtered_movies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(cr.role_count, 0) AS role_count
    FROM
        aka_title mt
    LEFT JOIN
        cast_roles cr ON mt.id = cr.movie_id
    WHERE
        mt.production_year BETWEEN 1990 AND 2020
)
SELECT 
    f.title AS movie_title,
    f.production_year,
    f.role_count,
    rt.titles_count AS same_year_title_count,
    LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors_names,
    CASE 
        WHEN f.role_count > 0 THEN 'Has Roles'
        ELSE 'No Roles'
    END AS role_presence,
    f.title || ' - ' || COALESCE(CAST(f.production_year AS TEXT), 'Unknown Year') AS title_with_year
FROM 
    filtered_movies f
JOIN
    ranked_titles rt ON f.movie_id = rt.title_id
LEFT JOIN
    cast_info ci ON f.movie_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
WHERE
    (f.role_count > 2 OR f.production_year IS NULL)
    AND rt.year_rank <= 5
GROUP BY 
    f.title, f.production_year, f.role_count, rt.titles_count
ORDER BY 
    f.production_year DESC, f.role_count DESC NULLS LAST;
