WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.character_name) AS characters,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM title t
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN char_name c ON ci.person_id = c.imdb_id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.imdb_id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
KeywordAssociations AS (
    SELECT 
        md.movie_title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM MovieDetails md
    JOIN movie_keyword mk ON md.movie_title = (SELECT title FROM title WHERE id = mk.movie_id)
    GROUP BY md.movie_title
)
SELECT 
    md.movie_title, 
    md.production_year, 
    md.characters, 
    md.companies, 
    ka.keyword_count
FROM MovieDetails md
LEFT JOIN KeywordAssociations ka ON md.movie_title = ka.movie_title
ORDER BY md.production_year DESC, ka.keyword_count DESC;
