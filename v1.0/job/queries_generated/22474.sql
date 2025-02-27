WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        -1 AS level,
        NULL AS parent_movie_id
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        level + 1,
        ml.movie_id
    FROM movie_link ml
    JOIN RecursiveMovieHierarchy rmh ON ml.movie_id = rmh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE rmh.level < 5  -- Limit depth of recursion
)

, CastDetails AS (
    SELECT 
        ci.movie_id,
        coalesce(an.name, cn.name, 'Unknown') AS actor_name, 
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order, 
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast,
        ci.note AS cast_note
    FROM cast_info ci
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN company_name cn ON ci.note IS NOT NULL AND cn.id = ci.note::int -- Assuming note can reference company ID
)

, MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    rmh.movie_id,
    rmh.movie_title,
    md.coalesce(cds.actor_name, 'N/A') AS first_actor,
    cds.total_cast,
    mk.keywords_list,
    CASE 
        WHEN rmh.level = 0 AND mk.keywords_list IS NOT NULL THEN 'Top Movie - Keywords Found'
        WHEN rmh.level = 0 THEN 'Top Movie - No Keywords'
        ELSE 'Linked Movie'
    END AS movie_category,
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = rmh.movie_id AND mi.info_type_id IS NULL -- Unusual; checking for NULL info types
    ) AS has_no_info_type
FROM RecursiveMovieHierarchy rmh
LEFT JOIN CastDetails cds ON rmh.movie_id = cds.movie_id AND cds.actor_order <= 3  -- Top 3 actors
LEFT JOIN MovieKeywords mk ON rmh.movie_id = mk.movie_id
ORDER BY rmh.movie_id, rmh.level DESC;
