WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS yearly_rank,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        MovieHierarchy m
    WHERE 
        m.level <= 2
),
Directors AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name) AS director_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.yearly_rank,
        rm.total_movies,
        d.director_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        Directors d ON rm.movie_id = d.movie_id
    WHERE 
        rm.total_movies > 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.director_names,
    COALESCE(fm.yearly_rank, 'N/A') AS movie_rank,
    CASE 
        WHEN fm.yearly_rank IS NULL THEN 'No Rank Available'
        ELSE 'Ranked'
    END AS rank_status
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.yearly_rank ASC 
LIMIT 50;
