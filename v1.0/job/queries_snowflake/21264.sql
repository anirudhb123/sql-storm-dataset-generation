
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        m.episode_of_id
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
SelectedGenres AS (
    SELECT 
        DISTINCT mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id, ci.movie_id
),
TopRoles AS (
    SELECT 
        pr.person_id,
        pr.movie_id,
        pr.role_count,
        ROW_NUMBER() OVER (PARTITION BY pr.person_id ORDER BY pr.role_count DESC) AS rn
    FROM 
        PersonRoles pr
),
MovieCount AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(tc.total_count, 0) AS total_cast,
        COALESCE(g.keyword_count, 0) AS keyword_count,
        (SELECT 
            COUNT(DISTINCT ci.person_id) 
         FROM 
            cast_info ci 
         WHERE 
            ci.movie_id = mh.movie_id) AS distinct_cast
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        (SELECT 
            movie_id, COUNT(*) AS total_count 
         FROM 
            cast_info 
         GROUP BY 
            movie_id) tc ON mh.movie_id = tc.movie_id
    LEFT JOIN 
        (SELECT 
            mk.movie_id, COUNT(DISTINCT mk.keyword_id) AS keyword_count 
         FROM 
            movie_keyword mk 
         GROUP BY 
            mk.movie_id) g ON mh.movie_id = g.movie_id
)
SELECT 
    mc.title,
    mc.production_year,
    mc.total_cast,
    mc.keyword_count,
    (SELECT 
        LISTAGG(DISTINCT a.name, ', ') 
     FROM 
        aka_name a 
     JOIN 
        cast_info ci ON a.person_id = ci.person_id 
     WHERE 
        ci.movie_id = mc.movie_id) AS starring_names,
    (SELECT 
        COUNT(*) 
     FROM 
        MovieHierarchy mh1 
     WHERE 
        mh1.episode_of_id = mc.movie_id) AS episode_count,
    CASE 
        WHEN mc.distinct_cast > 5 THEN 'Large Cast' 
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    MovieCount mc
WHERE 
    mc.production_year > 2000
    AND (mc.keyword_count > 1 OR mc.total_cast > 10)
ORDER BY 
    mc.production_year DESC, mc.total_cast DESC
LIMIT 10;
