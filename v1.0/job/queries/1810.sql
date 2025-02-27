WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name, 
        at.title AS movie_title, 
        at.production_year,
        COUNT(DISTINCT c.id) AS role_count
    FROM cast_info c
    JOIN aka_name ak ON c.person_id = ak.person_id
    JOIN aka_title at ON c.movie_id = at.movie_id
    WHERE ak.name IS NOT NULL
    GROUP BY ak.name, at.title, at.production_year
),
CompanyMovies AS (
    SELECT 
        cn.name AS company_name,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN aka_title mt ON mc.movie_id = mt.movie_id
    GROUP BY cn.name, mt.title, mt.production_year
)
SELECT 
    t.title, 
    t.production_year, 
    COALESCE(a.actor_name, 'No Actors') AS actor_name,
    COALESCE(c.company_name, 'No Companies') AS company_name,
    CASE
        WHEN a.role_count IS NULL THEN 'No Roles'
        ELSE CONCAT(a.role_count, ' Roles')
    END AS role_description,
    CASE
        WHEN c.company_count IS NULL THEN 'No Companies Linked'
        ELSE CONCAT(c.company_count, ' Companies Linked')
    END AS company_description
FROM RankedTitles t
LEFT JOIN ActorMovies a ON t.title = a.movie_title AND t.production_year = a.production_year
LEFT JOIN CompanyMovies c ON t.title = c.movie_title AND t.production_year = c.production_year
WHERE 
    (a.actor_name IS NOT NULL OR c.company_name IS NOT NULL)
ORDER BY t.production_year DESC, t.title;
