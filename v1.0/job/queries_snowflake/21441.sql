
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') AS company_names,
        LISTAGG(ct.kind, ', ') AS company_types,
        COUNT(*) FILTER (WHERE mc.note IS NOT NULL) AS company_notes_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    pr.role,
    pr.role_count,
    mci.company_names,
    mci.company_types,
    mci.company_notes_count,
    COALESCE(mci.company_notes_count, 0) AS non_null_company_notes,
    CASE 
        WHEN mci.company_notes_count IS NULL THEN 'No companies'
        ELSE 'Companies present: ' || mci.company_names
    END AS company_description,
    CASE 
        WHEN tm.production_year >= 2000 THEN 'Modern'
        WHEN tm.production_year < 2000 AND tm.production_year IS NOT NULL THEN 'Classic'
        ELSE 'Unknown'
    END AS era
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.title_id
LEFT JOIN 
    PersonRoles pr ON ci.person_id = pr.person_id
LEFT JOIN 
    MovieCompanyInfo mci ON tm.title_id = mci.movie_id
WHERE 
    pr.role_count > 1 OR pr.role IS NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title_id;
