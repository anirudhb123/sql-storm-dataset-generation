WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS avg_cast_note_presence,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN person_info pi ON c.person_id = pi.person_id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1
    WHERE (t.production_year IS NOT NULL OR t.production_year < 2000)
    GROUP BY t.id, t.title, t.production_year, k.keyword
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC, production_year ASC) AS overall_rank
    FROM movie_details
    WHERE rank_by_cast <= 5
),
selected_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        rm.keyword,
        rm.cast_count,
        rm.avg_cast_note_presence,
        COALESCE(SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_info_notes
    FROM ranked_movies rm
    LEFT JOIN person_info pi ON rm.movie_id = pi.person_id
    GROUP BY rm.movie_id, rm.title, rm.production_year, rm.keyword, rm.cast_count, rm.avg_cast_note_presence
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    sm.keyword,
    sm.cast_count,
    sm.avg_cast_note_presence,
    CASE WHEN sm.total_info_notes > 0 THEN 'Has Info' ELSE 'No Info' END AS info_status,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    CASE 
        WHEN sm.production_year IS NULL THEN 'Year Unknown'
        WHEN sm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM selected_movies sm
LEFT JOIN movie_companies mc ON sm.movie_id = mc.movie_id
LEFT JOIN company_name co ON mc.company_id = co.id 
GROUP BY sm.movie_id, sm.title, sm.production_year, 
         sm.keyword, sm.cast_count, sm.avg_cast_note_presence, sm.total_info_notes
HAVING COUNT(co.id) > 1 OR sm.avg_cast_note_presence > 0.5
ORDER BY sm.cast_count DESC, sm.production_year;
