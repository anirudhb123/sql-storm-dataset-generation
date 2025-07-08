
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Genre%')
    GROUP BY 
        mi.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS note_presence,
        LISTAGG(a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    mif.info_details,
    cd.total_cast,
    cd.note_presence,
    cd.cast_names
FROM 
    ranked_titles rt
LEFT JOIN 
    movie_info_filtered mif ON rt.title_id = mif.movie_id
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
WHERE 
    rt.year_rank <= 10
ORDER BY 
    rt.production_year DESC, cd.total_cast DESC
LIMIT 50;
