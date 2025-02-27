WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT ml.linked_movie_id, at.title, at.production_year, mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRankings AS (
    SELECT 
        a.id AS actor_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY a.id, ak.name
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, ct.kind
),
Compilation AS (
    SELECT 
        mh.title,
        mh.production_year,
        ar.name AS actor_name,
        ar.movie_count,
        cr.company_type,
        cr.company_count
    FROM MovieHierarchy mh
    LEFT JOIN ActorRankings ar ON mh.movie_id = ar.actor_id
    LEFT JOIN CompanyRoles cr ON mh.movie_id = cr.movie_id
)
SELECT 
    title,
    production_year,
    actor_name,
    movie_count,
    company_type,
    COALESCE(company_count, 0) AS company_count
FROM Compilation
WHERE 
    movie_count > 5 
    AND production_year >= 2000 
ORDER BY production_year DESC, movie_count DESC;
