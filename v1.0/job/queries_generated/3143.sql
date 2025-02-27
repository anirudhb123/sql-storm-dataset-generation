WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(cc.person_id) AS cast_count,
        SUM(CASE WHEN cc.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_count,
        STRING_AGG(ak.name, ', ') AS actor_names
    FROM aka_title mt
    JOIN cast_info cc ON mt.id = cc.movie_id
    LEFT JOIN aka_name ak ON cc.person_id = ak.person_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id, mt.title, mt.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        MAX(ct.kind) AS main_company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details,
        COUNT(DISTINCT it.info) AS info_type_count
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.has_note_count,
    md.actor_names,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(cd.main_company_type, 'Unknown') AS main_company_type,
    COALESCE(mid.info_details, 'No Info Available') AS info_details,
    mid.info_type_count
FROM movie_details md
LEFT JOIN company_details cd ON md.production_year = cd.movie_id
LEFT JOIN movie_info_details mid ON md.production_year = mid.movie_id
ORDER BY md.production_year DESC, md.cast_count DESC;
