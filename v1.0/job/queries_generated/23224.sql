WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        CONCAT(mh.title, ' - Related to: ', rt.title),
        mh.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS rt ON rt.id = ml.linked_movie_id
    WHERE 
        mh.depth < 3  -- Limit to 3 levels of hierarchy for performance purposes
),

ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT( DISTINCT cc.id) OVER (PARTITION BY ak.person_id) AS total_movies
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title AS at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
),

CompanyDetails AS (
    SELECT 
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.movie_id) AS total_movies_produced
    FROM 
        company_name AS cn
    JOIN 
        movie_companies AS mc ON cn.id = mc.company_id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        cn.name, ct.kind
),

AggregatedResults AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(a.actor_name, 'No Actor') AS lead_actor,
        COALESCE(c.company_name, 'No Company') AS production_company,
        COALESCE(c.total_movies_produced, 0) AS movies_by_company,
        COALESCE(a.total_movies, 0) AS actor_movie_count
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        ActorMovies AS a ON mh.movie_id = a.movie_title
    LEFT JOIN 
        CompanyDetails AS c ON mh.movie_id = c.total_movies_produced
)

SELECT 
    *,
    CASE 
        WHEN actor_movie_count > 10 THEN 'Prolific Actor'
        WHEN actor_movie_count BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Newcomer'
    END AS actor_status,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent Release'
    END AS movie_era
FROM 
    AggregatedResults
ORDER BY 
    movie_year DESC, lead_actor ASC NULLS LAST
LIMIT 100 OFFSET 0;
