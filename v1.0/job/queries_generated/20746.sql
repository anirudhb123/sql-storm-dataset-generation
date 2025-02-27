WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS rank_by_cast,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        ct.kind AS role_type,
        r.role AS role_name,
        m.title AS movie_title,
        m.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_title m ON c.movie_id = m.id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
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
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.rank_by_cast,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cd.role_name, 'Unknown Role') AS role_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    rm.total_cast,
    CASE 
        WHEN rm.total_cast > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.title_id = cd.movie_title
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2023)
    OR (mk.keywords LIKE '%action%' OR mk.keywords LIKE '%drama%')
ORDER BY 
    rm.production_year DESC,
    rm.rank_by_cast
LIMIT 100;
