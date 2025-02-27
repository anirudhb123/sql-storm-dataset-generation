WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.season_nr, 0) AS season_number,
        COALESCE(mt.episode_nr, 0) AS episode_number,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filtering recent movies
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        COALESCE(m.season_nr, 0),
        COALESCE(m.episode_nr, 0),
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    mh.season_number,
    mh.episode_number,
    COUNT(DISTINCT ci.id) OVER (PARTITION BY a.id ORDER BY mh.hierarchy_level) AS total_movies_as_actor,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    ROUND(AVG(mi.info::numeric), 2) AS avg_movie_info  -- assuming info is numeric
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')  -- Example for specific info_type
WHERE 
    a.name IS NOT NULL
    AND (t.production_year BETWEEN 2010 AND 2020 OR t.production_year IS NULL)  -- Complicated predicate
GROUP BY 
    a.id, t.title, mh.season_number, mh.episode_number
ORDER BY 
    total_movies_as_actor DESC, actor_name, movie_title;
