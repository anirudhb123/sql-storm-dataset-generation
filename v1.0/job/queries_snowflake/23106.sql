
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    AND 
        t.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        MIN(ct.kind) AS primary_company_type
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
    rt.production_year,
    rt.title,
    rt.title_rank,
    ar.actor_name,
    ar.role_name,
    ar.role_order,
    mk.keywords AS all_keywords,
    mci.companies,
    mci.primary_company_type
FROM
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rt.title_id = mci.movie_id
WHERE 
    rt.title_rank = 1 OR rt.title IS NULL
AND 
    (ar.role_name IS NOT NULL OR ar.actor_name IS NULL)
GROUP BY 
    rt.production_year, rt.title, rt.title_rank, ar.actor_name, ar.role_name, ar.role_order, mk.keywords, mci.companies, mci.primary_company_type
ORDER BY 
    rt.production_year DESC, rt.title;
