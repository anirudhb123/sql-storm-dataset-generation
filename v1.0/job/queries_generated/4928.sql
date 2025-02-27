WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mci.id) AS movie_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.year_rank,
    COALESCE(cd.company_name, 'No Company') AS company_info,
    COALESCE(cd.company_type, 'N/A') AS company_type_info,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    rm.cast_count,
    CASE 
        WHEN rm.cast_count > 5 THEN 'Blockbuster'
        WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Moderate Hit'
        ELSE 'Indie Flick'
    END AS movie_status
FROM RankedMovies rm
LEFT JOIN CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE rm.year_rank <= 10
ORDER BY rm.production_year DESC, rm.title;
