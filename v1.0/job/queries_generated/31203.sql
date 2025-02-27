WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)
, RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mt.production_year DESC) AS rank,
        COUNT(*) OVER (PARTITION BY mh.level) AS total_count
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.movie_id = mt.id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.level,
    rm.rank,
    rm.total_count,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    ct.kind AS company_type,
    CASE 
        WHEN km.keyword IS NOT NULL THEN km.keyword
        ELSE 'No Keywords'
    END AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.level, rm.rank;
