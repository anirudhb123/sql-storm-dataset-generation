WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies with their titles and years of production
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 as level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    -- Recursive case: Find sequels or related movies linked through movie_link
    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    -- Rank movies within each production year based on their names
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
    FROM 
        MovieHierarchy mh
),
CastDetails AS (
    -- Get the cast details for all ranked movies
    SELECT 
        r.movie_id,
        COUNT(c.id) AS cast_count,
        STRING_AGG(CONCAT(n.name, ' (', c.nr_order, ')'), ', ') AS cast_names
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info c ON r.movie_id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        r.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.title_rank,
    cd.cast_count,
    COALESCE(cd.cast_names, 'No cast info') AS cast_names,
    CASE 
        WHEN cd.cast_count > 5 THEN 'Large Cast'
        WHEN cd.cast_count IS NULL THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN rm.production_year IS NOT NULL THEN 
            CONCAT('Produced in ', rm.production_year)
        ELSE 
            'Year not specified'
    END AS production_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.title_rank <= 10 -- Getting top 10 movies per year
ORDER BY 
    rm.production_year DESC,
    rm.title_rank ASC;
