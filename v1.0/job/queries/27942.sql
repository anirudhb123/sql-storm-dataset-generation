
WITH movie_info_filtered AS (
    SELECT 
        mi.movie_id,
        mi.info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%rating%'
),

title_data AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'TV series'))
),

aka_names AS (
    SELECT 
        a.name AS aka_name,
        a.person_id,
        a.md5sum
    FROM 
        aka_name a
    WHERE 
        a.name ILIKE 'A%'
),

cast_details AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IN ('actor', 'actress')
),

final_benchmark AS (
    SELECT 
        tt.title,
        tt.production_year,
        an.aka_name,
        cd.role_name,
        mf.info AS movie_info_rating
    FROM 
        title_data tt
    JOIN 
        complete_cast cc ON tt.title_id = cc.movie_id
    JOIN 
        cast_details cd ON cc.subject_id = cd.person_id
    JOIN 
        aka_names an ON cd.person_id = an.person_id
    LEFT JOIN 
        movie_info_filtered mf ON tt.title_id = mf.movie_id
    WHERE 
        tt.production_year BETWEEN 2000 AND 2023
)

SELECT 
    title,
    production_year,
    aka_name,
    role_name,
    COALESCE(movie_info_rating, 'No Rating Available') AS rating_info
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, title;
