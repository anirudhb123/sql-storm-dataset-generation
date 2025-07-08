
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_types_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes
    FROM cast_info ci
    GROUP BY ci.movie_id
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    COALESCE(mc.company_names, 'No Companies') AS Companies,
    COALESCE(cs.total_actors, 0) AS Total_Actors,
    COALESCE(cs.actors_with_notes, 0) AS Actors_With_Notes,
    COALESCE(km.keywords, 'No Keywords') AS Keywords
FROM RankedTitles rt
LEFT JOIN MovieCompanies mc ON rt.title_id = mc.movie_id
LEFT JOIN CastStatistics cs ON rt.title_id = cs.movie_id
LEFT JOIN KeywordMovies km ON rt.title_id = km.movie_id
WHERE rt.title_rank = 1
ORDER BY rt.production_year DESC, rt.title;
