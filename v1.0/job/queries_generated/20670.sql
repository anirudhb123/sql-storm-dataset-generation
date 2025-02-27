WITH movie_rankings AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY t.id
),

top_movies AS (
    SELECT 
        mr.title_id,
        mr.title,
        mr.production_year,
        mr.total_cast,
        mr.avg_cast_order
    FROM movie_rankings mr
    WHERE mr.year_rank <= 5
),

movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS production_companies,
        COALESCE(STRING_AGG(DISTINCT pi.info, '; '), 'No Info') AS additional_info
    FROM top_movies tm
    LEFT JOIN movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_info mi ON tm.title_id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN person_info pi ON pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.title_id)
    GROUP BY tm.title_id
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.production_companies,
    md.additional_info,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_category,
    CASE WHEN md.additional_info LIKE '%Oscar%' THEN 'Has Oscar' ELSE 'No Oscar' END AS oscar_status
FROM movie_details md
WHERE md.title ILIKE '%the%'
ORDER BY md.production_year DESC, md.title;
