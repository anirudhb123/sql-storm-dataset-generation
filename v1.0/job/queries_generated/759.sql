WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT c.id) AS cast_count
    FROM complete_cast mt
    JOIN cast_info ci ON mt.subject_id = ci.person_id
    GROUP BY mt.movie_id
    HAVING COUNT(DISTINCT c.id) > 2
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code IS NOT NULL
)

SELECT 
    rt.title,
    rt.production_year,
    COALESCE(pm.cast_count, 0) AS total_cast,
    mk.keywords,
    cm.company_name,
    cm.company_type
FROM RankedTitles rt
LEFT JOIN PopularMovies pm ON rt.title_id = pm.movie_id
LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE rt.rn <= 10
ORDER BY rt.production_year DESC, rt.title;
