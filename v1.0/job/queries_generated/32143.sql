WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS TEXT) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' --> ', mt.title) AS path
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        CAST(COALESCE(ki.keyword, '-') AS TEXT) AS keyword_used,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.actor_name) AS actor_count,
        STRING_AGG(cd.keyword_used, '; ') AS keywords_list,
        MAX(cd.actor_order) AS order_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keywords_list,
    CASE 
        WHEN ms.actor_count > 5 THEN 'High'
        WHEN ms.actor_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low' 
    END AS actor_density,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    MovieStats ms
LEFT JOIN 
    movie_companies mc ON ms.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
WHERE 
    ms.keywords_list LIKE '%action%' 
    OR ms.actor_count > 2
ORDER BY 
    ms.production_year DESC, 
    ms.actor_count DESC;
