WITH RecursivePersonTitles AS (
    SELECT 
        a.person_id AS person_id,
        t.title AS title,
        t.production_year AS production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
CompCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM movie_companies m
    JOIN company_name co ON m.company_id = co.id
    GROUP BY m.movie_id
),
FilteredMovies AS (
    SELECT 
        pt.person_id,
        pt.title,
        pt.production_year,
        cc.total_cast,
        mc.companies
    FROM RecursivePersonTitles pt
    LEFT JOIN CompCast cc ON pt.person_id = cc.movie_id
    LEFT JOIN MovieCompanies mc ON pt.person_id = mc.movie_id
    WHERE pt.rn = 1
),
FinalOutput AS (
    SELECT 
        f.person_id,
        f.title,
        f.production_year,
        COALESCE(f.total_cast, 0) AS total_cast,
        COALESCE(f.companies, 'None') AS companies,
        CASE 
            WHEN f.total_cast > 10 THEN 'Large Ensemble'
            WHEN f.total_cast BETWEEN 5 AND 10 THEN 'Medium Ensemble'
            WHEN f.total_cast < 5 THEN 'Small Cast'
            ELSE 'Unknown'
        END AS cast_size
    FROM FilteredMovies f
)
SELECT 
    fo.person_id,
    fo.title,
    fo.production_year,
    fo.total_cast,
    fo.companies,
    fo.cast_size,
    (SELECT COUNT(*) FROM role_type) AS total_role_types,
    (SELECT COUNT(DISTINCT keyword) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT movie_id FROM movie_companies mc WHERE mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'US'))) AS total_us_keywords
FROM FinalOutput fo
ORDER BY fo.production_year DESC, fo.total_cast DESC
LIMIT 100;
