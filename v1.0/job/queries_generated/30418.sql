WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Filter for movies produced from the year 2000

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
    WHERE
        at.production_year >= 2000  -- Ensure linking is to movies also produced after 2000
),
TopMovies AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        MovieHierarchy mv
    LEFT JOIN 
        complete_cast cc ON mv.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        ci.movie_id IS NOT NULL
    GROUP BY 
        mv.movie_id
    ORDER BY 
        cast_count DESC
    LIMIT 10  -- Get top 10 movies based on cast count
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        string_agg(DISTINCT ak.name, ', ') AS actor_names,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id IS NOT NULL) AS info_count,  -- Subquery to count associated info entries
    ROW_NUMBER() OVER (ORDER BY md.keyword_count DESC) AS rank  -- Ranking movies based on keyword count
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0  -- Only include movies that have associated keywords
ORDER BY 
    md.keyword_count DESC, md.title ASC;  -- Order by keyword count and title
