WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        k.keyword,
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ci.movie_id, k.keyword
),
ActorNames AS (
    SELECT 
        ak.person_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS name_rank
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ar.role_count, 0) AS total_roles,
    COALESCE(cm.company_count, 0) AS total_companies,
    AN.name,
    AN.name_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyMovieCount cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    ActorNames AN ON ar.movie_id = (
        SELECT movie_id 
        FROM cast_info ci 
        WHERE ci.person_id = AN.person_id 
        ORDER BY ci.nr_order LIMIT 1
    )
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, total_roles DESC, AN.name_rank
LIMIT 100;
