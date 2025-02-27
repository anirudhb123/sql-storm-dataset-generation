WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(c.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
ActorsMovies AS (
    SELECT 
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        c.nr_order
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN title m ON ci.movie_id = m.id
    LEFT JOIN RankedMovies rm ON m.id = rm.id
    LEFT JOIN CompanyStats cs ON m.id = cs.movie_id
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    cs.company_count,
    cs.company_names,
    CASE 
        WHEN am.rank <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS rank_category
FROM ActorsMovies am
JOIN CompanyStats cs ON am.movie_title = cs.movie_title
WHERE am.nr_order IS NOT NULL
ORDER BY am.production_year DESC, am.actor_name;
