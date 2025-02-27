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
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        mh.level = 1
),
GenreMovies AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT mk.keyword_id) AS genre_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.title
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.company_count,
        COALESCE(gm.genre_count, 0) AS genre_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        GenreMovies gm ON rm.title = gm.title
    WHERE 
        rm.rank <= 10 -- Top 10 in each production year
)

SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.company_count,
    fr.genre_count,
    CASE 
        WHEN fr.cast_count > 20 THEN 'High Cast'
        WHEN fr.cast_count BETWEEN 10 AND 20 THEN 'Moderate Cast'
        ELSE 'Low Cast'
    END AS cast_category
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.cast_count DESC;
