WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        c.nr_order,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
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
    cd.actor_role,
    ci.company_name,
    ci.company_type,
    kw.keywords_list,
    COALESCE(cd.total_cast, 0) AS total_cast_members,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top 5 Films of the Year'
        ELSE 'Other Films'
    END AS release_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    Keywords kw ON rm.movie_id = kw.movie_id
WHERE 
    (rm.production_year > 2000 OR ci.company_type IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.movie_id;
