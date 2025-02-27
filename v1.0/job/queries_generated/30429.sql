WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        c.actor_count,
        k.keywords
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        MovieKeywords k ON mh.movie_id = k.movie_id
)
SELECT 
    dmi.movie_title,
    dmi.production_year,
    COALESCE(dmi.actor_count, 0) AS total_actors,
    COALESCE(dmi.keywords, 'No keywords available') AS movie_keywords,
    CASE 
        WHEN dmi.production_year < 2010 THEN 'Older'
        ELSE 'Recent'
    END AS movie_age,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = dmi.movie_id 
     AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')
    ) AS distributor_count
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.actor_count > (SELECT AVG(actor_count) FROM CastInfoWithRoles)
ORDER BY 
    dmi.production_year DESC, dmi.movie_title;
