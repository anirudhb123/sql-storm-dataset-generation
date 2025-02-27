WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM
        aka_title t
    WHERE
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        ot.id AS movie_id,
        ot.title,
        ot.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM
        aka_title ot
    JOIN MovieHierarchy mh ON ot.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM
        MovieHierarchy mh
    WHERE
        mh.level <= 3
),
PopularActors AS (
    SELECT
        ci.person_id,
        COUNT(*) AS movie_count
    FROM
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(*) > 5
),
ActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name,
        p.info_text AS biography
    FROM 
        aka_name a
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        p.info_type_id = (SELECT id FROM info_type WHERE info = 'biography')
),
MoviesWithActors AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        ad.name AS actor_name,
        ad.biography
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorDetails ad ON ci.person_id = ad.actor_id
)
SELECT
    mwa.title,
    mwa.production_year,
    COUNT(DISTINCT mwa.actor_name) AS actor_count,
    STRING_AGG(DISTINCT mwa.actor_name, ', ') AS actor_names,
    CASE
        WHEN COUNT(DISTINCT mwa.actor_name) > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    MoviesWithActors mwa
LEFT JOIN 
    movie_info mi ON mwa.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    mi.info IS NOT NULL
GROUP BY 
    mwa.movie_id
HAVING 
    COUNT(DISTINCT mwa.actor_name) > 0
ORDER BY 
    popularity_category DESC, mwa.production_year DESC;
