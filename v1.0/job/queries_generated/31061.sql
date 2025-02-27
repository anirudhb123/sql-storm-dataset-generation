WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ml.linked_movie_id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
),
cast_details AS (
    SELECT 
        ci.person_id,
        ci.movie_id, 
        an.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
        CASE 
            WHEN ci.note IS NOT NULL THEN ci.note 
            ELSE 'No additional information' 
        END AS actor_note
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.actor_order,
    cd.actor_note,
    mk.keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    (mh.production_year BETWEEN 2010 AND 2023 OR mk.keywords IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    cd.actor_order;
