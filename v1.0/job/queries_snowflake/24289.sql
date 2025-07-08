
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        CT.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type CT ON mc.company_type_id = CT.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
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
)
SELECT 
    rm.title AS movie_title,
    cm.company_name,
    cd.actor_name,
    cd.role_name,
    mk.keywords,
    COALESCE(CAST(bi.info AS TEXT), 'No Information') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.title_id = cm.movie_id
LEFT JOIN 
    CastDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    (SELECT 
         mi.movie_id,
         LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info
     FROM 
         movie_info mi
     WHERE 
         mi.info IS NOT NULL
     GROUP BY 
         mi.movie_id
    ) bi ON rm.title_id = bi.movie_id
WHERE 
    rm.year_rank <= 5 AND 
    (cd.role_name LIKE '%Director%' OR cd.actor_name LIKE '%John%')
ORDER BY 
    rm.production_year DESC, 
    cd.nr_order
LIMIT 100;
