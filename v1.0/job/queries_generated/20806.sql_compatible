
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_title_id, 
        mt.title, 
        mt.production_year,
        mt.kind_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN mc.note IS NOT NULL THEN 'Yes' ELSE 'No' END) AS has_notes
    FROM aka_title mt
    LEFT JOIN cast_info ci ON ci.movie_id = mt.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN movie_companies mc ON mc.movie_id = mt.movie_id
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.id, mt.title, mt.production_year, mt.kind_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
FinalResults AS (
    SELECT 
        md.movie_title_id,
        md.title,
        md.production_year,
        md.aka_names,
        md.lead_cast_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        md.company_count,
        md.has_notes,
        ROW_NUMBER() OVER (PARTITION BY md.kind_id ORDER BY md.production_year DESC) AS row_num
    FROM MovieDetails md
    LEFT JOIN KeywordCount kc ON kc.movie_id = md.movie_title_id
)

SELECT 
    fr.title,
    fr.production_year,
    fr.aka_names,
    fr.lead_cast_count,
    fr.keyword_count,
    fr.company_count,
    fr.has_notes
FROM FinalResults fr
WHERE fr.row_num <= 5 
AND fr.lead_cast_count > 0
ORDER BY fr.production_year DESC, fr.title;
