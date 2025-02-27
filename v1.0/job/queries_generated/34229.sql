WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        0 AS hierarchy_level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies after 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id, 
        m.title, 
        m.production_year, 
        m.kind_id,
        mh.hierarchy_level + 1
    FROM 
        movie_link AS ml
    JOIN 
        title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.*, 
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_in_year
    FROM 
        MovieHierarchy AS m
),
CastCount AS (
    SELECT 
        c.movie_id, 
        COUNT(*) AS total_cast
    FROM 
        cast_info AS c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        COALESCE(cc.total_cast, 0) AS total_cast, 
        COALESCE(n.name, 'Unknown') AS lead_actor_name
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CastCount AS cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON rm.movie_id = ci.movie_id AND ci.nr_order = 1  -- Get the lead actor
    LEFT JOIN 
        aka_name AS n ON ci.person_id = n.person_id
)
SELECT 
    md.movie_id, 
    md.title,
    md.production_year,
    md.total_cast,
    md.lead_actor_name,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    MovieDetails AS md
WHERE 
    md.rank_in_year <= 5  -- Only top 5 movies in each year
ORDER BY 
    md.production_year DESC, 
    md.title;
