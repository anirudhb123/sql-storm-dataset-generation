WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.movie_id) DESC) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year, k.keyword
),
MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
FilteredMovies AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(r.keyword, 'No Keywords') AS movie_keyword,
        COALESCE(mr.role_count, 0) AS actor_count,
        COALESCE(cr.company_count, 0) AS production_company_count
    FROM 
        aka_title t
    LEFT JOIN 
        RankedMovies r ON t.production_year = r.production_year AND r.keyword_rank = 1
    LEFT JOIN 
        MovieRoles mr ON t.id = mr.movie_id
    LEFT JOIN 
        CompanyRoles cr ON t.id = cr.movie_id
),
FinalResults AS (
    SELECT 
        f.title,
        f.production_year,
        f.movie_keyword,
        f.actor_count,
        f.production_company_count,
        CASE 
            WHEN f.actor_count > 5 AND f.production_company_count > 2 THEN 'Blockbuster'
            WHEN f.actor_count = 0 THEN 'Documentary or Lesser Known'
            ELSE 'Standard Movie'
        END AS movie_type
    FROM 
        FilteredMovies f
)
SELECT 
    fr.title,
    fr.production_year,
    fr.movie_keyword,
    fr.actor_count,
    fr.production_company_count,
    fr.movie_type
FROM 
    FinalResults fr
WHERE 
    (fr.production_year >= 2000 AND fr.actor_count > 0) 
    OR (fr.production_year < 2000 AND fr.movie_type = 'Documentary or Lesser Known')
ORDER BY 
    fr.production_year DESC, 
    fr.actor_count DESC,
    fr.production_company_count ASC
LIMIT 100;
