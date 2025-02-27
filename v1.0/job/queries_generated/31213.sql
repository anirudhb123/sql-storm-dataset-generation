WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
TopKeywords AS (
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
        COUNT(*) > 5
),
TitleCast AS (
    SELECT 
        mt.id AS movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        mt.id, a.name
),
FinalBenchmark AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.level,
        mh.path,
        t.actor_name,
        COALESCE(t.role_count, 0) AS role_count,
        COALESCE(tk.keyword_count, 0) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TitleCast t ON mh.movie_id = t.movie_id
    LEFT JOIN 
        TopKeywords tk ON mh.movie_id = tk.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.level,
    fb.path,
    fb.actor_name,
    fb.role_count,
    fb.keyword_count,
    (fb.role_count + fb.keyword_count) AS total_score
FROM 
    FinalBenchmark fb
WHERE 
    fb.level = 1 -- Only select the top level movies
ORDER BY 
    total_score DESC
LIMIT 10;
