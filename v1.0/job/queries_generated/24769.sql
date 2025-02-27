WITH RECURSIVE CompanyHierarchy AS (
    SELECT cm.movie_id,
           cn.name AS company_name,
           ct.kind AS company_type,
           1 AS level
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE mc.note IS NOT NULL

    UNION ALL

    SELECT mc.movie_id,
           cn.name AS company_name,
           ct.kind AS company_type,
           ch.level + 1
    FROM CompanyHierarchy ch
    JOIN movie_companies mc ON mc.movie_id = ch.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE mc.note IS NULL
),
TitleCounts AS (
    SELECT title.id AS title_id,
           title.title,
           COUNT(DISTINCT cast.id) AS actor_count,
           SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
           STRING_AGG(DISTINCT ci.note, '; ') AS notes_aggregation
    FROM title
    LEFT JOIN cast_info ci ON ci.movie_id = title.id
    LEFT JOIN aka_title at ON title.id = at.movie_id
    LEFT JOIN aka_name an ON an.person_id = ci.person_id
    GROUP BY title.id
),
HighProductionYears AS (
    SELECT production_year,
           COUNT(*) AS title_count
    FROM aka_title
    WHERE kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
    GROUP BY production_year
    HAVING COUNT(*) > 10
),
RankedTitles AS (
    SELECT title.id, 
           title.title,
           row_number() OVER(ORDER BY title.production_year DESC, actor_count DESC) AS rank,
           COALESCE(htc.title_count, 0) AS high_year_count
    FROM TitleCounts tt
    LEFT JOIN HighProductionYears htc ON tt.production_year = htc.production_year
    JOIN title ON title.id = tt.title_id
),
FinalResults AS (
    SELECT rt.title,
           rt.rank,
           rt.high_year_count,
           COUNT(DISTINCT ch.company_name) AS total_companies,
           SUM(CASE WHEN rt.high_year_count > 0 THEN 1 ELSE 0 END) AS marked_high_year
    FROM RankedTitles rt
    LEFT JOIN CompanyHierarchy ch ON ch.movie_id = rt.id
    GROUP BY rt.title, rt.rank, rt.high_year_count
)
SELECT *,
       CASE WHEN total_companies > 5 THEN 'High' ELSE 'Low' END AS company_association,
       CASE WHEN marked_high_year > 0 THEN 'Featured' ELSE 'Standard' END AS feature_flag
FROM FinalResults
ORDER BY rank ASC, high_year_count DESC;
