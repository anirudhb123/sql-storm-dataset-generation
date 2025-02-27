WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
role_summary AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
null_filter AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        ak.person_id,
        COALESCE(ci.movie_id, -1) AS movie_id
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    nt.aka_name,
    rt.title,
    rt.production_year,
    rs.movie_count,
    rs.roles,
    nt.movie_id,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic' 
        ELSE 'Modern' 
    END AS era,
    'A.K.A. "' || nt.aka_name || '" featured in "' || rt.title || '" (' || rt.production_year || ')' AS full_description
FROM 
    null_filter nt
JOIN 
    ranked_titles rt ON nt.movie_id = rt.id
JOIN 
    role_summary rs ON nt.person_id = rs.person_id
WHERE 
    rs.movie_count > 1 
    AND nt.movie_id IS NOT NULL 
    AND nt.movie_id NOT IN (
        SELECT movie_id 
        FROM movie_info 
        WHERE info_type_id = (
            SELECT id FROM info_type WHERE info = 'Notable' 
        )
    )
ORDER BY 
    rt.production_year DESC NULLS LAST, 
    nt.aka_name ASC
LIMIT 50;
