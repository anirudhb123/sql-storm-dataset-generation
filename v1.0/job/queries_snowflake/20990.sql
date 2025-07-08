
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(NULLIF(c.nr_order, 0), 99) AS actor_order,
        r.role AS role_description
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, '; ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        mc.company_type_id IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.actor_order,
    cd.role_description,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(comp.company_names, 'No Companies') AS production_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON cd.movie_id = rm.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN 
    CompanyDetails comp ON comp.movie_id = rm.movie_id
WHERE 
    rm.title_rank <= 5 
    AND (cd.actor_order < 3 OR cd.role_description IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
