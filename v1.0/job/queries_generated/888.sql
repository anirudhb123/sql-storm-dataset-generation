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
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'N/A') AS production_company,
    COUNT(DISTINCT cd.company_name) AS company_count,
    STRING_AGG(DISTINCT kd.keyword, ', ') AS keywords,
    COALESCE((SELECT COUNT(*) FROM CastDetails ca WHERE ca.movie_id = rm.movie_id), 0) AS actor_count,
    COUNT(DISTINCT ca.actor_name) AS unique_actors,
    MAX(ca.actor_order) AS highest_order
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CastDetails ca ON rm.movie_id = ca.movie_id
LEFT JOIN 
    KeywordDetails kd ON rm.movie_id = kd.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
HAVING 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.title;
