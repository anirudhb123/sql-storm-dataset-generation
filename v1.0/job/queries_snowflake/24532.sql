
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    WHERE mt.production_year IS NOT NULL
    GROUP BY mt.title, mt.production_year
),
TopRankedMovies AS (
    SELECT 
        production_year,
        title,
        cast_count
    FROM RankedMovies
    WHERE rank <= 3
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.note IS NULL
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        tr.title,
        tr.production_year,
        tr.cast_count,
        ci.company_count,
        ci.company_names
    FROM TopRankedMovies tr
    LEFT JOIN CompanyInfo ci ON tr.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
),
KeywordCounts AS (
    SELECT
        mt.id AS movie_id,
        COUNT(mk.id) AS keyword_count
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id
),
FinalDetails AS (
    SELECT
        md.title,
        md.production_year,
        md.cast_count,
        md.company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM MovieDetails md
    LEFT JOIN KeywordCounts kc ON md.title = (SELECT title FROM aka_title WHERE id = kc.movie_id LIMIT 1)
)
SELECT 
    fd.title,
    fd.production_year,
    fd.cast_count,
    fd.company_count,
    fd.keyword_count,
    CASE 
        WHEN fd.company_count > 10 THEN 'Blockbuster'
        WHEN fd.cast_count > 20 THEN 'Ensemble Cast'
        ELSE 'Standard'
    END AS movie_category
FROM FinalDetails fd
WHERE fd.production_year IN (SELECT DISTINCT production_year FROM FinalDetails WHERE keyword_count >= 3)
ORDER BY fd.production_year DESC, fd.cast_count DESC;
