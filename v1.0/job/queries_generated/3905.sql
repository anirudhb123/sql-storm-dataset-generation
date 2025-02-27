WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.info_type_id DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    WHERE 
        m.info_type_id IS NOT NULL
), ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IS NOT NULL
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
), MovieKeywords AS (
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
    COALESCE(ar.name, 'Unknown Actor') AS actor_name,
    ar.role,
    COALESCE(cd.company_name, 'Independent') AS production_company,
    cd.company_type,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top 3' 
        ELSE 'Other' 
    END AS ranking_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.role_order
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, rm.title;
