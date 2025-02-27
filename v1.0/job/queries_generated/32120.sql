WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')      
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
FinalResults AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cd.actor_name,
        cd.role_name,
        COALESCE(pk.keyword, 'No Keywords') AS popular_keyword,
        mh.level
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        PopularKeywords pk ON mh.movie_id = pk.movie_id
    WHERE 
        mh.production_year >= 2000
    ORDER BY 
        mh.production_year DESC, mh.movie_title
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    role_name,
    popular_keyword,
    level
FROM 
    FinalResults
WHERE 
    actor_order = 1
OFFSET 0 LIMIT 10;
