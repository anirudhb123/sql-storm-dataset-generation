WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth,
        NULL AS parent_id
    FROM title m
    WHERE m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.depth + 1 AS depth,
        mh.movie_id AS parent_id
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        ci.role_id,
        r.role AS character_name,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY t.production_year DESC) AS role_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE 
        ci.nr_order IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title m ON mk.movie_id = m.id
    GROUP BY m.id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.depth,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(arrs.actor_names, 'No Actors') AS actor_names
    FROM MovieHierarchy mh
    LEFT JOIN MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT 
            movie_title,
            STRING_AGG(actor_name, ', ') AS actor_names
        FROM ActorRoles
        WHERE role_rank <= 3
        GROUP BY movie_title
    ) arrs ON mh.title = arrs.movie_title
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.depth,
    fm.keywords,
    fm.actor_names
FROM FilteredMovies fm
WHERE fm.depth = (SELECT MAX(depth) FROM MovieHierarchy)
ORDER BY fm.title;
