WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        pt.title AS parent_title,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title pt ON mt.episode_of_id = pt.id
    
    UNION ALL

    SELECT 
        pt.id AS movie_id,
        pt.title AS movie_title,
        pt.production_year,
        mt.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title pt
    JOIN 
        MovieHierarchy mh ON pt.episode_of_id = mh.movie_id
),
QualifiedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.parent_title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_level
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    qm.movie_title,
    qm.production_year,
    COUNT(DISTINCT ar.person_id) AS total_actors,
    STRING_AGG(DISTINCT ar.actor_role, ', ') AS roles,
    COALESCE(MAX(ci.num_movies), 0) AS total_companies,
    CASE 
        WHEN qm.level > 0 THEN 'Episode'
        ELSE 'Movie'
    END AS type,
    SUM(CASE WHEN ci.company_type = 'Distributor' THEN ci.num_movies ELSE 0 END) AS distributors_count
FROM 
    QualifiedMovies qm
LEFT JOIN 
    ActorRoles ar ON qm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyInfo ci ON qm.movie_id = ci.movie_id
WHERE 
    (qm.production_year >= 2000 AND qm.level = 0) OR
    (qm.production_year < 2000 AND qm.level > 0)
GROUP BY 
    qm.movie_title, qm.production_year, qm.level
HAVING 
    COUNT(DISTINCT ar.person_id) > 2
ORDER BY 
    qm.production_year DESC, total_actors DESC;
