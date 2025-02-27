WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 0 AS depth
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.depth + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.nr_order IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (ORDER BY mh.depth, mh.production_year DESC) AS movie_rank,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
        COALESCE(RC.actor_name, 'No Actors') AS actor_name
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        RankedCast RC ON mh.movie_id = RC.movie_id AND RC.actor_rank = 1
    WHERE 
        mh.production_year IS NOT NULL AND
        mh.title IS NOT NULL
)
SELECT 
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.actor_name
FROM 
    FilteredMovies fm
WHERE 
    fm.movie_rank <= 10
ORDER BY 
    fm.production_year DESC;
