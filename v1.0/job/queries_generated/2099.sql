WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year, 
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        cty.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
    GROUP BY 
        mc.movie_id, cn.name, cty.kind
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    cd.company_name,
    cd.company_type,
    COALESCE(cd.company_count, 0) AS company_count,
    COUNT(DISTINCT rm.actor_name) OVER (PARTITION BY rm.production_year) AS total_actors_per_year,
    CASE 
        WHEN rm.actor_rank <= 3 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_role
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.production_year = cd.movie_id
WHERE 
    rm.actor_name IS NOT NULL 
    AND rm.actor_name NOT LIKE '%Test%'
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
