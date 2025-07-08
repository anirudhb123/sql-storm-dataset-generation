
WITH RECURSIVE movie_series AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS movie_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NOT NULL

    UNION ALL

    SELECT 
        t.title,
        t.production_year,
        t.id AS movie_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        ms.level + 1
    FROM title t
    JOIN movie_series ms ON t.episode_of_id = ms.movie_id
),

cast_details AS (
    SELECT 
        c.movie_id,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS lead_actor_ratio
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

movie_info_ext AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, '{No additional info}') AS info,
        COALESCE(mi.note, 'N/A') AS note
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
),

final_output AS (
    SELECT 
        t.title,
        t.production_year,
        cast_details.cast_names,
        cast_details.cast_count,
        LEAD(cast_details.cast_count) OVER (ORDER BY t.production_year) AS next_cast_count,
        movie_keywords.keywords,
        movie_info_ext.info,
        movie_info_ext.note,
        CASE 
            WHEN ms.level IS NOT NULL THEN 
                CONCAT('Part of a series with ', ms.level, ' levels.')
            ELSE 
                'Standalone movie'
        END AS movie_series_info
    FROM title t
    LEFT JOIN cast_details ON t.id = cast_details.movie_id
    LEFT JOIN movie_keywords ON t.id = movie_keywords.movie_id
    LEFT JOIN movie_info_ext ON t.id = movie_info_ext.movie_id
    LEFT JOIN movie_series ms ON t.id = ms.movie_id
)

SELECT 
    title,
    production_year,
    cast_names,
    cast_count,
    next_cast_count,
    keywords,
    info,
    note,
    movie_series_info
FROM final_output
WHERE production_year >= 2000
ORDER BY production_year DESC, cast_count DESC
LIMIT 100;
