WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mt.kind AS movie_type,
        0 AS hierarchy_level
    FROM 
        aka_title m
    JOIN 
        kind_type mt ON m.kind_id = mt.id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        kt.kind AS movie_type,
        mh.hierarchy_level + 1 
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        kind_type kt ON at.kind_id = kt.id
    WHERE 
        kt.kind IN ('feature', 'short')
),
TotalCast AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.movie_type,
        COALESCE(tc.total_cast, 0) AS total_cast,
        mh.hierarchy_level
    FROM
        MovieHierarchy mh
    LEFT JOIN 
        TotalCast tc ON mh.movie_id = tc.movie_id
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank_by_cast
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 0
)
SELECT
    r.movie_title,
    r.production_year,
    r.movie_type,
    r.total_cast,
    r.hierarchy_level,
    CASE 
        WHEN r.rank_by_cast <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS cast_rank_category
FROM 
    RankedMovies r
WHERE 
    r.hierarchy_level = 0
ORDER BY 
    r.production_year DESC, 
    r.total_cast DESC;
