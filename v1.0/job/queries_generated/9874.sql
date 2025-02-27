WITH movie_stats AS (
    SELECT t.id AS movie_id,
           t.title,
           COUNT(DISTINCT c.person_id) AS cast_count,
           MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword END) AS main_keyword,
           AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS average_note_present
    FROM title t
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN cast_info c ON c.movie_id = cc.movie_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN person_info pi ON pi.person_id = c.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title
),
company_data AS (
    SELECT mc.movie_id,
           GROUP_CONCAT(DISTINCT cn.name) AS companies,
           GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT ms.movie_id,
       ms.title,
       ms.cast_count,
       ms.main_keyword,
       ms.average_note_present,
       cd.companies,
       cd.company_types
FROM movie_stats ms
LEFT JOIN company_data cd ON ms.movie_id = cd.movie_id
WHERE ms.cast_count > 5
ORDER BY ms.average_note_present DESC, ms.cast_count DESC;
