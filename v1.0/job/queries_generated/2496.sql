WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    GROUP BY c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.company_id) AS total_companies,
        MAX(m.name) AS main_company
    FROM movie_companies mc
    JOIN company_name m ON m.id = mc.company_id
    GROUP BY mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keywords_count
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(mcomp.total_companies, 0) AS total_companies,
    COALESCE(mcomp.main_company, 'Unknown') AS main_company,
    COALESCE(mk.keywords_count, 0) AS keywords_count,
    CASE 
        WHEN rm.rank IS NULL THEN 'Not Ranked' 
        ELSE 'Ranked: ' || rm.rank 
    END AS ranking_status
FROM RankedMovies rm
LEFT JOIN CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN MovieCompanies mcomp ON rm.movie_id = mcomp.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE rm.production_year > 2000
ORDER BY rm.production_year DESC, rm.title;
