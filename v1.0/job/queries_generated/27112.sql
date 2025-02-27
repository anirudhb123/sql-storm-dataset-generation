WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ct.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ct.id) DESC) AS title_rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN char_name ch ON an.name = ch.name
    LEFT JOIN keyword k ON t.id = k.id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE t.production_year >= 2000
      AND cn.country_code = 'USA'
      AND rt.role IN ('Actor', 'Actress')
    GROUP BY t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        mi.info AS movie_info,
        mi.note AS info_note
    FROM movie_info m
    JOIN movie_info_idx mi ON m.movie_id = mi.movie_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT 
    rt.title,
    rt.production_year,
    rt.cast_count,
    COUNT(mo.movie_info) AS info_count,
    STRING_AGG(DISTINCT mo.movie_info, '; ') AS all_info,
    STRING_AGG(DISTINCT an.name, ', ') AS all_cast
FROM RankedTitles rt
LEFT JOIN MovieInfo mo ON rt.title = mo.movie_info
LEFT JOIN cast_info ci ON rt.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
LEFT JOIN aka_name an ON ci.person_id = an.person_id
WHERE rt.title_rank = 1
GROUP BY rt.title, rt.production_year, rt.cast_count
ORDER BY rt.cast_count DESC, rt.production_year DESC
LIMIT 10;
This query benchmarks string processing by calculating the number of cast members per title, gathers additional movie information with conditions, and aggregates the results into a coherent output. It utilizes common table expressions (CTEs) to create manageable subsets of data, which can be beneficial for performance when benchmarking string processing tasks.
