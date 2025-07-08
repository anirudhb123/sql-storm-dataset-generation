
WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.imdb_index
),

company_details AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),

info_details AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS movie_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
),

final_output AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        COALESCE(cd.company_names, 'No Companies') AS company_names,
        COALESCE(cd.company_types, 'No Types') AS company_types,
        COALESCE(id.movie_info, 'No Info') AS movie_info
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.title_id = cd.movie_id
    LEFT JOIN 
        info_details id ON md.title_id = id.movie_id
)

SELECT 
    fo.*,
    CASE 
        WHEN fo.actor_count > 5 THEN 'Blockbuster'
        WHEN fo.actor_count BETWEEN 3 AND 5 THEN 'Popular'
        ELSE 'Indie'
    END AS movie_category,
    RANK() OVER (ORDER BY fo.production_year DESC, fo.actor_count DESC) AS rank
FROM 
    final_output fo
WHERE 
    fo.production_year BETWEEN 2000 AND 2023
ORDER BY 
    fo.production_year DESC, fo.actor_count DESC
LIMIT 50;
