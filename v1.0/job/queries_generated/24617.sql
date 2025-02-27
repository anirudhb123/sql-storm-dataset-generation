WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorWithRoles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON m.id = mk.movie_id
    GROUP BY 
        m.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
MoviesWithActorRoles AS (
    SELECT 
        r.movie_id,
        r.actor_id,
        r.actor_name,
        r.role_name,
        COALESCE(m.keywords, 'No keywords') AS keywords,
        COALESCE(mci.company_count, 0) AS company_count
    FROM 
        ActorWithRoles r
    LEFT JOIN 
        MovieKeywords m ON r.movie_id = m.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON r.movie_id = mci.movie_id
)
SELECT 
    mm.movie_id,
    mm.title,
    mm.production_year,
    mm.actor_name,
    mm.role_name,
    mm.keywords,
    mm.company_count
FROM 
    MoviesWithActorRoles mm
JOIN 
    RankedMovies rm ON mm.movie_id = rm.movie_id
WHERE 
    mm.role_rank = 1 
    AND rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, 
    mm.actor_name ASC
FETCH FIRST 100 ROWS ONLY;
