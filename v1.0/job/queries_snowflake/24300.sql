
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id, 
        a.name, 
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS actor_role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
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
MoviesAndDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.keywords_list,
        mci.companies,
        mci.company_types,
        COALESCE(ar.name, 'Unknown Actor') AS actor_name,
        ar.role AS actor_role,
        ar.actor_role_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords ak ON rm.movie_id = ak.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    title, 
    production_year, 
    keywords_list, 
    companies, 
    company_types, 
    actor_name, 
    actor_role,
    COUNT(*) OVER (PARTITION BY title) AS actor_count,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year >= 2000 AND production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE
        WHEN companies IS NULL THEN 'Unproduced'
        ELSE 'Produced'
    END AS production_status
FROM 
    MoviesAndDetails
WHERE 
    actor_role_rank <= 3
ORDER BY 
    production_year DESC, actor_count DESC, title;
