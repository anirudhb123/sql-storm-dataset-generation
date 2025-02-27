WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        COUNT(DISTINCT ci.person_role_id) AS roles_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    WHERE 
        a.name IS NOT NULL 
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 1
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mi.movie_id) AS related_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        cm.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, cm.name, ct.kind
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(fa.total_movies, 0) AS actor_movies,
    COALESCE(fa.roles_count, 0) AS actor_roles,
    cs.company_name,
    cs.company_type,
    cs.related_movies,
    CASE 
        WHEN fa.total_movies > 5 THEN 'Star'
        WHEN fa.total_movies BETWEEN 3 AND 5 THEN 'Supporting'
        ELSE 'Cameo' 
    END AS actor_category
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON rm.movie_id = fa.total_movies
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.movie_count > 10 
    AND (fa.total_movies IS NULL OR fa.roles_count < 2) 
ORDER BY 
    rm.production_year DESC,
    rm.title_rank DESC
LIMIT 100;

