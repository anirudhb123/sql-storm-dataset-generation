WITH RecursiveActorHierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        t.title,
        t.production_year,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ra.actor_id) AS actor_count,
        MAX(ra.actor_order) AS max_actor_order
    FROM 
        aka_title t
    LEFT JOIN 
        RecursiveActorHierarchy ra ON t.id = ra.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT ra.actor_id) > 5 
        AND MAX(ra.actor_order) < 4
),
CostlyActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        filteredmovies fm ON ci.movie_id = fm.movie_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT m.movie_id) > 3
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(ca.actor_count, 0) AS number_of_actors,
    COALESCE(mci.company_count, 0) AS number_of_companies,
    ca.name AS prominent_actor
FROM 
    FilteredMovies fm
LEFT JOIN 
    CostlyActors ca ON fm.movie_id = ca.movie_count
LEFT JOIN 
    MovieCompanyInfo mci ON fm.movie_id = mci.movie_id
WHERE 
    (mci.company_count IS NULL OR mci.company_count < 2)
    AND (fm.actor_count > 10 OR (fm.production_year IS NOT NULL AND fm.production_year < 2015))
ORDER BY 
    fm.production_year DESC, fm.title ASC
LIMIT 100;
