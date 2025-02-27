WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(cast_actors.actor_names, 'Unknown') AS actor_names,
        0 AS depth
    FROM aka_title mt
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            STRING_AGG(CONCAT(aka.name, ' (', COALESCE(rol.role, 'Unknown'), ')'), ', ') AS actor_names
        FROM cast_info ci
        LEFT JOIN aka_name aka ON ci.person_id = aka.person_id
        LEFT JOIN role_type rol ON ci.role_id = rol.id
        GROUP BY ci.movie_id
    ) AS cast_actors ON mt.id = cast_actors.movie_id
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(cast_actors.actor_names, 'Unknown') AS actor_names,
        depth + 1 AS depth
    FROM movie_link ml
    JOIN MovieHierarchy mt ON ml.movie_id = mt.movie_id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            STRING_AGG(CONCAT(aka.name, ' (', COALESCE(rol.role, 'Unknown'), ')'), ', ') AS actor_names
        FROM cast_info ci
        LEFT JOIN aka_name aka ON ci.person_id = aka.person_id
        LEFT JOIN role_type rol ON ci.role_id = rol.id
        GROUP BY ci.movie_id
    ) AS cast_actors ON ml.linked_movie_id = cast_actors.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.actor_names,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth, mh.title) AS rn
    FROM MovieHierarchy mh
    WHERE mh.production_year BETWEEN 1990 AND 2020 
    AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_names,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = fm.movie_id AND mi.info ILIKE '%Academy Award%') THEN 'Oscar Winner'
        ELSE 'Not an Oscar Winner'
    END AS academy_status,
    CASE 
        WHEN fm.depth = 0 THEN 'Direct Movie'
        WHEN fm.depth = 1 THEN 'Sequel/Related'
        ELSE 'Franchise'
    END AS movie_tier
FROM FilteredMovies fm
WHERE rn <= 10  -- Limit to top 10 movies per year
ORDER BY fm.production_year, fm.title;
