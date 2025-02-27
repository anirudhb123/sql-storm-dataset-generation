WITH RecursiveMovie AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY k.keyword) AS keyword_rank,
        (SELECT COUNT(DISTINCT ci.person_id) 
         FROM cast_info ci 
         WHERE ci.movie_id = mt.id) AS total_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        total_cast
    FROM 
        RecursiveMovie
    WHERE 
        keyword_rank <= 3 
        OR production_year = (SELECT MAX(production_year) FROM RecursiveMovie)
),
ExtendedMovieInfo AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.keyword,
        fm.total_cast,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS leading_roles,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON fm.movie_id = mc.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, fm.keyword, fm.total_cast
),
FinalResults AS (
    SELECT 
        emi.*, 
        CASE 
            WHEN emi.total_cast = 0 THEN 'No Cast Info' 
            ELSE 'Has Cast Info' 
        END AS cast_info_status,
        SUM(emi.total_cast) OVER () AS all_time_cast_count,
        STRING_AGG(DISTINCT emi.keyword, ', ') AS aggregated_keywords
    FROM 
        ExtendedMovieInfo emi
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keyword,
    fr.total_cast,
    fr.leading_roles,
    fr.production_companies,
    fr.cast_info_status,
    fr.all_time_cast_count,
    fr.aggregated_keywords
FROM 
    FinalResults fr
WHERE 
    fr.production_companies > 0 
    AND fr.leading_roles > 1
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
