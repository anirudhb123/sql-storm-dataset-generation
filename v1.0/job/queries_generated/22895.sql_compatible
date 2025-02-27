
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
        CASE 
            WHEN ci.note LIKE '%cameo%' THEN 'Cameo'
            ELSE 'Regular'
        END AS role_type
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),

MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mg.genres, 'Unknown Genre') AS genres,
        COUNT(DISTINCT cd.actor_name) AS total_actors
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieGenres mg ON mh.movie_id = mg.movie_id
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mg.genres
    HAVING 
        COUNT(DISTINCT cd.actor_name) > 3 
)

SELECT 
    fm.title,
    fm.production_year,
    fm.genres,
    fm.total_actors,
    (SELECT ROUND(AVG(rank)) FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY ci.nr_order) AS rank
        FROM cast_info ci 
        WHERE ci.movie_id = fm.movie_id
    ) w) AS avg_actor_rank
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.total_actors DESC
LIMIT 10;
