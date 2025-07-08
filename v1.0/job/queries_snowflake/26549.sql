WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        cp.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cp ON mc.company_type_id = cp.id
),
KeywordFiltering AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.phonetic_code LIKE 'A%' 
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    ai.actor_name,
    ai.actor_role,
    cd.company_name,
    cd.company_type,
    kf.keyword
FROM 
    RankedMovies rm
JOIN 
    ActorInfo ai ON rm.movie_id = ai.movie_id AND ai.actor_rank <= 3 
JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    KeywordFiltering kf ON rm.movie_id = kf.movie_id
WHERE 
    rm.rank <= 5 
ORDER BY 
    rm.kind_id, rm.production_year DESC, ai.actor_rank;