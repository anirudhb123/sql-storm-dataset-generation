WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
        
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_level
    FROM
        MovieHierarchy mh
),
ActorsWithRole AS (
    SELECT
        ak.name AS actor_name,
        ct.kind AS role,
        mu.title AS movie_title,
        mu.production_year
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        title mu ON ci.movie_id = mu.id
    LEFT JOIN
        comp_cast_type ct ON ci.person_role_id = ct.id
),
DistinctKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    DISTINCT am.actor_name,
    am.role,
    rm.title,
    rm.production_year,
    rk.rank_level,
    COALESCE(dk.keywords, 'No Keywords') AS keywords
FROM
    ActorsWithRole am
JOIN
    RankedMovies rm ON am.movie_title = rm.title AND am.production_year = rm.production_year
LEFT JOIN
    DistinctKeywords dk ON rm.movie_id = dk.movie_id
WHERE
    rm.rank_level <= 3
ORDER BY
    rm.production_year DESC, 
    am.actor_name;
