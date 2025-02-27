WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year,
        COUNT(*) OVER () AS total_movies
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CastSummary AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
        STRING_AGG(DISTINCT CASE WHEN n.gender IS NOT NULL THEN n.gender ELSE 'Unknown' END, ', ') AS genders
    FROM cast_info c
    JOIN RankedMovies m ON c.movie_id = m.movie_id
    LEFT JOIN name n ON c.person_id = n.imdb_id
    GROUP BY m.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name || ' (' || ct.kind || ')', ', ') AS companies_involved
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        cs.total_cast,
        cs.note_count,
        cs.genders,
        coalesce(ci.companies_involved, 'No companies') AS companies_involved
    FROM RankedMovies rm
    LEFT JOIN CastSummary cs ON rm.movie_id = cs.movie_id
    LEFT JOIN CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    note_count,
    genders,
    companies_involved,
    CASE 
        WHEN total_cast IS NULL THEN 'No Cast Info'
        WHEN total_cast = 0 THEN 'No Cast Available'
        WHEN note_count > 0 THEN 'Cast Notes Present'
        ELSE 'No Notes for Cast'
    END AS cast_info_summary
FROM FinalResults
WHERE production_year < 2000 
AND total_cast IS NOT NULL 
ORDER BY production_year DESC, title ASC;
