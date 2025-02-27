WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        mt.id::text AS path,
        ARRAY[mt.title] AS full_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        l.linked_movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.level + 1,
        mh.path || '->' || l.linked_movie_id::text,
        mh.full_path || lt.title
    FROM 
        movie_link l
    JOIN 
        aka_title lt ON l.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON l.movie_id = mh.movie_id
),
actor_performance AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT at.title, ', ') AS movies
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ci.nr_order = 1
    GROUP BY 
        a.person_id
),
most_active_actors AS (
    SELECT 
        ap.person_id,
        ap.movie_count,
        ap.role_count,
        ap.movies,
        RANK() OVER (ORDER BY ap.movie_count DESC, ap.role_count DESC) AS actor_rank
    FROM 
        actor_performance ap
    WHERE 
        ap.movie_count > (SELECT AVG(movie_count) FROM actor_performance)
    AND 
        ap.role_count > 2
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    WHERE 
        mh.level < 3
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.movie_keyword,
    ma.person_id,
    ma.movies
FROM 
    filtered_movies f
LEFT JOIN 
    most_active_actors ma ON ma.movies LIKE '%' || f.title || '%'
WHERE 
    f.production_year IS NOT NULL
    AND f.movie_keyword IS NOT NULL
ORDER BY 
    f.production_year DESC, 
    ma.actor_rank
LIMIT 50;
