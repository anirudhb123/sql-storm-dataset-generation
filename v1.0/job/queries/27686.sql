WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title t
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
company_data AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
info_data AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS movie_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    COALESCE(cd.company_names, 'N/A') AS company_names,
    COALESCE(cd.company_types, 'N/A') AS company_types,
    COALESCE(id.movie_info, 'No additional information') AS additional_info
FROM movie_data md
LEFT JOIN company_data cd ON md.movie_id = cd.movie_id
LEFT JOIN info_data id ON md.movie_id = id.movie_id
ORDER BY md.production_year DESC, md.cast_count DESC;
