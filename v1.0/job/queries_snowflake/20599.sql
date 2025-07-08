
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, c.role_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
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
    t.title,
    t.production_year,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(cr.actor_names, 'No Cast') AS actor_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_names, 'No Companies') AS company_names,
    COALESCE(mc.company_types, 'No Types') AS company_types,
    RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS production_rank
FROM 
    RankedMovies t
LEFT JOIN 
    CastRoles cr ON t.title_id = cr.movie_id
LEFT JOIN 
    MovieKeywords mk ON t.title_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON t.title_id = mc.movie_id
WHERE 
    t.title_rank <= 10 OR t.production_year = (SELECT MAX(production_year) FROM aka_title)
GROUP BY 
    t.title, t.production_year, cr.actor_count, cr.actor_names, mk.keywords, mc.company_names, mc.company_types, t.title_rank
ORDER BY 
    t.production_year DESC,
    t.title;
