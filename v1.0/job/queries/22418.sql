WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role,
    cd.nr_order,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_count, 0) AS company_count,
    (CASE
        WHEN mc.company_count = 1 THEN 'One Company'
        WHEN mc.company_count > 1 THEN 'Multiple Companies'
        ELSE 'No Companies'
    END) AS company_status,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id IS NOT NULL) AS info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 5 
ORDER BY 
    rm.production_year, rm.title, cd.nr_order
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;