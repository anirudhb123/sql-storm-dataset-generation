
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        p.name AS actor_name,
        r.role AS actor_role,
        COALESCE(n.name_pcode_cf, 'N/A') AS name_code
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        name n ON p.name = n.name
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT comp.name || ' (' || ct.kind || ')', ', ') WITHIN GROUP (ORDER BY comp.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name comp ON m.company_id = comp.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    R.movie_id,
    R.title,
    R.production_year,
    CD.actor_name,
    CD.actor_role,
    CD.name_code,
    COALESCE(CD.actor_role, 'Unknown Role') AS safe_actor_role,
    CASE 
        WHEN R.title_rank IS NULL THEN 'No Rank Available'
        ELSE 'Rank: ' || CAST(R.title_rank AS VARCHAR)
    END AS title_rank_description,
    CASE
        WHEN C.companies IS NULL THEN 'No Companies'
        ELSE C.companies
    END AS production_companies,
    (SELECT COUNT(*) FROM movie_keyword k WHERE k.movie_id = R.movie_id) AS keyword_count
FROM 
    RankedMovies R
LEFT JOIN 
    CastDetails CD ON R.movie_id = CD.movie_id
LEFT JOIN 
    CompanyDetails C ON R.movie_id = C.movie_id
WHERE 
    (R.production_year BETWEEN 2000 AND 2020 OR R.production_year IS NULL)
    AND (CD.actor_name LIKE '%John%' OR CD.actor_name IS NULL)
ORDER BY 
    R.production_year DESC, R.title;
