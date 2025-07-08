
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        at.title,
        at.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 3
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_keywords AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ak.keywords,
        ar.actor_name,
        ar.role_count,
        mh.level
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keywords ak ON mh.movie_id = ak.movie_id
    LEFT JOIN 
        actor_roles ar ON mh.movie_id = ar.movie_id
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    COALESCE(mwk.keywords, 'No Keywords') AS keywords,
    COALESCE(mwk.actor_name, 'Unknown Actor') AS actor_name,
    mwk.role_count,
    mwk.level,
    CASE 
        WHEN mwk.role_count IS NULL THEN 'No Roles'
        WHEN mwk.role_count > 0 AND mwk.level > 1 THEN 'Multi-Level Movie'
        ELSE 'Basic Movie'
    END AS movie_status
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mwk.production_year DESC, 
    mwk.level ASC,
    mwk.role_count DESC;
