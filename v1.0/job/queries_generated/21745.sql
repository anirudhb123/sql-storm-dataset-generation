WITH RecursiveMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
    UNION ALL
    SELECT 
        t.id AS movie_id,
        CONCAT(t.title, ' - ', t.production_year) AS title,
        t.production_year,
        NULL AS keyword
    FROM 
        aka_title t
    INNER JOIN 
        RecursiveMovies rm ON t.id = rm.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY ct.kind) AS company_order
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        ci.company_name,
        ci.company_type,
        ar.actor_order,
        ci.company_order,
        COALESCE(ar.actor_order, 0) AS adjusted_actor_order,
        COALESCE(ci.company_order, 0) AS adjusted_company_order
    FROM 
        RecursiveMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' as ' || role_name, ', ') AS actors,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS companies,
    COUNT(DISTINCT actor_name) AS number_of_actors,
    COUNT(DISTINCT company_name) AS number_of_companies,
    MAX(adjusted_actor_order) AS max_actor_order,
    MAX(adjusted_company_order) AS max_company_order,
    CASE 
        WHEN COUNT(DISTINCT actor_name) = 0 THEN 'No Actors'
        WHEN COUNT(DISTINCT company_name) = 0 THEN 'No Companies'
        ELSE 'All Good'
    END AS benchmark_status
FROM 
    FinalBenchmark
GROUP BY 
    movie_id, title, production_year
HAVING 
    (MAX(adjusted_actor_order) > 0 AND MAX(adjusted_company_order) > 1) OR 
    (COUNT(DISTINCT actor_name) = 0 OR COUNT(DISTINCT company_name) = 0)
ORDER BY 
    production_year DESC, COUNT(DISTINCT actor_name) DESC
OFFSET 10 LIMIT 50;
