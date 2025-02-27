WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    INNER JOIN comp_cast_type ct ON c.person_role_id = ct.id
),

MovieCompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    INNER JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        c.actor_name,
        c.role_type,
        mcs.company_count,
        mcs.company_names,
        CASE 
            WHEN mcs.company_count IS NULL THEN 'No Companies'
            ELSE 'Has Companies'
        END AS company_status
    FROM MovieHierarchy mh
    LEFT JOIN CastInfoWithRoles c ON mh.movie_id = c.movie_id
    LEFT JOIN MovieCompanyStats mcs ON mh.movie_id = mcs.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_type,
    md.company_count,
    md.company_names,
    md.company_status,
    RANK() OVER (ORDER BY md.production_year DESC, md.movie_title) AS movie_rank
FROM MovieDetails md
WHERE 
    md.company_status = 'Has Companies'
    AND md.actor_rank <= 3 
ORDER BY md.production_year DESC, md.movie_title;
