
WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year > 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, h.level + 1
    FROM aka_title m
    JOIN MovieHierarchy h ON m.episode_of_id = h.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cd.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'None') AS keywords 
    FROM MovieHierarchy mh
    LEFT JOIN CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.keywords
FROM FilteredMovies fm
WHERE fm.total_actors > 5 
AND fm.production_year BETWEEN 2010 AND 2023
ORDER BY fm.production_year DESC, fm.total_actors DESC
LIMIT 100;
