WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
, CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
, TitleRank AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cd.actor_name) AS actor_count,
        RANK() OVER (ORDER BY COUNT(cd.actor_name) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id,
        mh.title,
        mh.production_year
)
SELECT 
    tr.title,
    tr.production_year,
    tr.actor_count,
    (SELECT STRING_AGG(CONCAT('Role: ', cd.role_name, ', Actor: ', cd.actor_name), '; ')
     FROM CastDetails cd 
     WHERE cd.movie_id = tr.movie_id) AS roles_and_actors,
    CASE 
        WHEN tr.actor_count IS NULL THEN 'No Actors'
        WHEN tr.actor_count > 10 THEN 'Blockbuster'
        ELSE 'Independent'
    END AS movie_type
FROM 
    TitleRank tr
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.rank;
