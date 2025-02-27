WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year IS NOT NULL
),
ActorStatistics AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN r.role LIKE 'Lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),
MovieSummary AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.movie_id,
        COALESCE(as.actor_count, 0) AS total_actors,
        COALESCE(as.lead_roles, 0) AS total_leads,
        COALESCE(ci.company_count, 0) AS total_companies,
        COALESCE(ci.company_names, 'None') AS companies_involved,
        rm.keyword_count
    FROM RankedMovies rm
    LEFT JOIN ActorStatistics as ON rm.movie_id = as.movie_id
    LEFT JOIN CompanyInformation ci ON rm.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_actors,
    total_leads,
    total_companies,
    companies_involved,
    keyword_count
FROM MovieSummary
WHERE (total_actors > 0 AND keyword_count > 2)
   OR (total_leads > 0 AND total_companies = 0)
ORDER BY production_year DESC, total_actors DESC, title;

