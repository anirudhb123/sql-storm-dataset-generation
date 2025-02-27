WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregateMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(mi.info) AS plot_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    ami.title,
    ami.production_year,
    ami.actor_count,
    ami.actor_names,
    COALESCE(ami.plot_info, 'No plot information available') AS plot_info,
    ami.keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ami.production_year ORDER BY ami.actor_count DESC) AS rank_within_year
FROM 
    AggregateMovieInfo ami
WHERE 
    ami.actor_count > 0
ORDER BY 
    ami.production_year DESC, 
    ami.actor_count DESC
LIMIT 10;
