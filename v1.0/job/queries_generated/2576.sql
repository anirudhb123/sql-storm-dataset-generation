WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COALESCE(SUM(DISTINCT mc.company_type_id), 0) AS company_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    GROUP BY a.id
), RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_per_year
    FROM MovieDetails md
), FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.company_count, 
        rm.cast_count, 
        rm.keyword_count
    FROM RankedMovies rm
    WHERE rm.rank_per_year <= 10
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(NULLIF(fm.company_count, 0), 'No Companies') AS company_info,
    fm.cast_count,
    fm.keyword_count,
    CASE 
        WHEN fm.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM FilteredMovies fm
ORDER BY fm.production_year DESC, fm.cast_count DESC;
