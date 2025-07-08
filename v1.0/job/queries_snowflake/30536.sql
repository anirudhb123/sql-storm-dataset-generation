
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM title t
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link mt
    JOIN title t ON mt.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mt.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN title t ON ci.movie_id = t.id
    GROUP BY ci.person_id, a.name
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
ProductionOverview AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ar.actor_name, 'Unknown') AS actors,
        COALESCE(cm.companies, 'No Companies') AS companies,
        COALESCE(cm.company_count, 0) AS total_companies,
        mh.level
    FROM MovieHierarchy mh
    LEFT JOIN ActorRoles ar ON mh.movie_id = ar.movie_count
    LEFT JOIN CompanyMovies cm ON mh.movie_id = cm.movie_id
)
SELECT 
    po.title,
    po.production_year,
    po.actors,
    po.companies,
    po.total_companies,
    po.level,
    RANK() OVER (PARTITION BY po.level ORDER BY po.production_year DESC) AS year_rank,
    CASE 
        WHEN po.total_companies > 0 THEN 'Has Companies' 
        ELSE 'No Companies' 
    END AS company_status
FROM ProductionOverview po
WHERE po.production_year >= 2000
ORDER BY po.level, po.production_year DESC;
