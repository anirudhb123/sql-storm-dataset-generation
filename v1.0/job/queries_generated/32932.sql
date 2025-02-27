WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::text AS parent_title
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.title AS parent_title
    FROM 
        aka_title AS et
    INNER JOIN 
        MovieHierarchy AS mh ON et.episode_of_id = mh.movie_id
), 
CastRanked AS (
    SELECT 
        ci.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
), 
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(CASE WHEN cr.actor_rank <= 3 THEN 1 ELSE 0 END), 0) AS top_actors_count,
        COALESCE(MAX(cr.actor_rank), 0) AS highest_actor_rank
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        CastRanked AS cr ON mh.movie_id = cr.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    fm.top_actors_count,
    fm.highest_actor_rank,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    movie_keyword AS mk ON fm.movie_id = mk.movie_id
WHERE 
    fm.production_year BETWEEN 2000 AND 2020
    AND fm.top_actors_count > 0
GROUP BY 
    fm.title, fm.production_year, fm.top_actors_count, fm.highest_actor_rank
ORDER BY 
    fm.production_year DESC, fm.top_actors_count DESC, fm.highest_actor_rank ASC
LIMIT 10;
