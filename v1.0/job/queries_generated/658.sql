WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(cs.total_cast, 0) AS num_cast,
        cs.cast_names
    FROM 
        ranked_titles m
    LEFT JOIN 
        cast_summary cs ON m.title_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    kt.kind,
    md.num_cast,
    CASE 
        WHEN md.num_cast > 10 THEN 'Large Cast'
        WHEN md.num_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    md.cast_names
FROM 
    movie_details md
JOIN 
    kind_type kt ON md.kind_id = kt.id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.num_cast DESC;
