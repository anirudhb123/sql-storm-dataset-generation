WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth
    FROM 
        aka_title AS t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        depth + 1
    FROM 
        movie_link AS m
    JOIN 
        aka_title AS t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy AS mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COALESCE(ci.actor_count, 0) AS total_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.depth
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    CastInfo AS ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.depth = 0
ORDER BY 
    mh.production_year DESC, 
    total_actors DESC
LIMIT 10;
