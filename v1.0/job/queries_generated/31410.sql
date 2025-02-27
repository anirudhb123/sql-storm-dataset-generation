WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title
    ORDER BY 
        company_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.company_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        MAX(pi.info) AS director_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id 
    WHERE 
        it.info = 'Director'
    GROUP BY 
        tm.movie_id, tm.title, tm.company_count
)
SELECT 
    md.title,
    md.company_count,
    COALESCE(md.actors, 'No cast available') AS actors,
    COALESCE(md.director_info, 'Unknown') AS director_info,
    CASE 
        WHEN md.company_count > 5 THEN 'High Production Value'
        WHEN md.company_count BETWEEN 3 AND 5 THEN 'Moderate Production Value'
        ELSE 'Low Production Value'
    END AS production_value_category
FROM 
    MovieDetails md
ORDER BY 
    md.company_count DESC;
