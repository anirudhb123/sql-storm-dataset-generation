WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        string_agg(DISTINCT ak.name, ', ') AS aka_names,
        string_agg(DISTINCT gn.kind, ', ') AS genres,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM title m
    LEFT JOIN aka_title ak ON m.id = ak.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN kind_type gn ON m.kind_id = gn.id
    GROUP BY m.id, m.title, m.production_year
),
cast_data AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT CONCAT_WS(' as ', pn.name, rt.role), ', ') AS cast_list
    FROM cast_info ci
    JOIN aka_name pn ON ci.person_id = pn.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
info_data AS (
    SELECT 
        mi.movie_id,
        string_agg(DISTINCT CONCAT_WS(': ', it.info, mi.info), '; ') AS movie_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    cd.cast_list,
    md.keywords,
    id.movie_info
FROM movie_data md
LEFT JOIN cast_data cd ON md.movie_id = cd.movie_id
LEFT JOIN info_data id ON md.movie_id = id.movie_id
WHERE md.production_year >= 2000
ORDER BY md.production_year DESC;
