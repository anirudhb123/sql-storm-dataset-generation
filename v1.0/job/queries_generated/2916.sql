WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(r.role) AS main_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    cd.actor_count,
    cd.main_role,
    co.company_name,
    co.company_type,
    kw.keyword_list,
    CASE 
        WHEN cd.actor_count IS NULL THEN 'No actors'
        WHEN cd.actor_count > 5 THEN 'Many actors'
        ELSE 'Few actors'
    END AS actor_category
FROM 
    RankedTitles tt
LEFT JOIN 
    CastDetails cd ON tt.title_id = cd.movie_id
LEFT JOIN 
    CompanyDetails co ON tt.title_id = co.movie_id
LEFT JOIN 
    Keywords kw ON tt.title_id = kw.movie_id
WHERE 
    tt.title_rank = 1
ORDER BY 
    tt.production_year DESC, tt.title ASC;
