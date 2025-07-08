
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorsRoles AS (
    SELECT 
        c.movie_id,
        ak.person_id,
        ak.name,
        r.role AS actor_role,
        COUNT(c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, ak.person_id, ak.name, r.role
),
Companies AS (
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
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    COALESCE(ar.name, 'No actors') AS actor_name,
    COALESCE(ar.actor_role, 'N/A') AS actor_role,
    COALESCE(c.company_names, 'No company') AS movie_companies,
    COALESCE(c.company_types, 'N/A') AS company_types,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Unknown Year'
        WHEN rm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY rm.title) AS yearly_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsRoles ar ON rm.movie_id = ar.movie_id
FULL OUTER JOIN 
    Companies c ON rm.movie_id = c.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (rm.production_year IS NOT NULL AND rm.production_year > 1990) 
    OR (ar.role_count IS NOT NULL AND ar.role_count > 0)
ORDER BY 
    rm.production_year DESC, yearly_rank;
