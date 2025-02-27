WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        p.name AS actor_name,
        t.title AS movie_title,
        mr.production_year,
        ROW_NUMBER() OVER (PARTITION BY mr.id ORDER BY c.nr_order) AS role_order,
        COALESCE(k.keyword, 'No Keyword') AS keyword_desc
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        MovieHierarchy mr ON t.id = mr.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mr.level <= 3
),
AggregatedRoles AS (
    SELECT 
        actor_name,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies,
        COUNT(*) AS total_roles
    FROM 
        CastDetails
    GROUP BY 
        actor_name
)
SELECT 
    ar.actor_name,
    ar.movies,
    ar.total_roles,
    COUNT(DISTINCT mc.company_id) AS company_count,
    CASE 
        WHEN ar.total_roles > 5 THEN 'Prolific'
        WHEN ar.total_roles BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Newcomer'
    END AS role_category
FROM 
    AggregatedRoles ar
LEFT JOIN 
    movie_companies mc ON ar.movies LIKE '%' || mc.movie_id || '%'
GROUP BY 
    ar.actor_name, ar.movies, ar.total_roles
ORDER BY 
    role_category DESC, ar.total_roles DESC;
