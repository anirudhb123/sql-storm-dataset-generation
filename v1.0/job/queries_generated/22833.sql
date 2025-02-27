WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM title t
    WHERE t.production_year >= 2000
),
TitleAggregates AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.rank_by_title,
        rt.total_titles,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM RankedTitles rt
    LEFT JOIN cast_info ci ON rt.title_id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY rt.title_id, rt.title, rt.production_year, rt.rank_by_title, rt.total_titles
    HAVING COUNT(ci.person_id) > 0
),
FilteredAggregates AS (
    SELECT 
        ta.title,
        ta.production_year,
        ta.cast_count,
        ta.actor_names,
        ta.null_notes_count,
        total_titles,
        CASE 
            WHEN ta.cast_count > (total_titles / 2) THEN 'Majority Cast'
            ELSE 'Minority Cast'
        END AS cast_proportion
    FROM TitleAggregates ta
    JOIN (SELECT DISTINCT production_year, total_titles FROM RankedTitles) tt ON ta.production_year = tt.production_year
)
SELECT 
    fa.title,
    fa.production_year,
    fa.cast_count,
    fa.actor_names,
    fa.null_notes_count,
    fa.cast_proportion,
    COALESCE(NULLIF(fa.actor_names, ''), 'No Cast Data') AS safe_actor_names,
    CASE 
        WHEN fa.null_notes_count > 0 THEN 'Some Notes Missing'
        ELSE 'All Notes Present'
    END AS note_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = fa.title_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) 
        THEN 'Has Budget Info'
        ELSE 'No Budget Info'
    END AS budget_info_status
FROM FilteredAggregates fa
ORDER BY fa.production_year DESC, fa.cast_count DESC, fa.title;
