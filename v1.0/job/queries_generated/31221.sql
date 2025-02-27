WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS level
    FROM cast_info ci
    WHERE ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor') -- Starting with Lead Actors

    UNION ALL

    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.level + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id != ah.person_id -- Avoid self-join
),
CompanyProjects AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS project_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, cn.name, ct.kind
),
RelevantMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ah.level AS hierarchy_level,
        COUNT(DISTINCT kp.keyword) AS keyword_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_keyword kp ON t.id = kp.movie_id
    JOIN ActorHierarchy ah ON ah.person_id = ci.person_id
    WHERE t.production_year >= 2000 -- Filtering to focus on movies from the 2000's onward
    GROUP BY a.id, a.name, t.id, t.title, t.production_year, ah.level
)
SELECT 
    rm.actor_id,
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    rm.hierarchy_level,
    COALESCE(cp.company_name, 'Independent') AS production_company,
    COALESCE(cp.company_type, 'N/A') AS company_type,
    rm.keyword_count
FROM RelevantMovies rm
LEFT JOIN CompanyProjects cp ON rm.movie_id = cp.movie_id
ORDER BY rm.hierarchy_level, rm.production_year DESC, rm.actor_name;
