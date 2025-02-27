WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year, 
           1 AS level
    FROM aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id, 
           m.title, 
           m.production_year, 
           h.level + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy h ON ml.movie_id = h.movie_id
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(m.id) OVER (PARTITION BY m.production_year) AS total_movies
    FROM aka_title m
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mr.title_rank, 0) AS title_rank,
        COALESCE(mr.total_movies, 0) AS total_movies,
        ARRAY_AGG(DISTINCT ar.actor_name) AS actor_names
    FROM MovieHierarchy mh
    LEFT JOIN RankedMovies mr ON mh.movie_id = mr.movie_id
    LEFT JOIN ActorRoles ar ON mh.movie_id = ar.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mr.title_rank, mr.total_movies
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.title_rank,
    fm.total_movies,
    fm.actor_names,
    NULLIF(fm.total_movies, 0) AS non_zero_movies,
    CASE WHEN fm.title_rank = 1 THEN 'First in Production Year' 
         ELSE 'Not the First' END AS rank_status
FROM FilteredMovies fm
WHERE fm.production_year >= 2000
ORDER BY fm.production_year DESC, fm.title_rank;
