WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
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
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
),
FinalResults AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        tm.num_actors,
        mi.keywords,
        COALESCE(ROUND(AVG(CASE WHEN pi.info_type_id = 1 THEN pi.info::numeric END), 2), 0) AS avg_rating
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieInfo mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_info mpi ON tm.movie_id = mpi.movie_id
    LEFT JOIN 
        person_info pi ON pi.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = tm.movie_id)
    WHERE 
        tm.rank <= 10
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year, tm.num_actors, mi.keywords
)
SELECT 
    *,
    CASE 
        WHEN avg_rating IS NULL THEN 'No Rating'
        WHEN avg_rating > 7.5 THEN 'Highly Rated'
        WHEN avg_rating > 5 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_category
FROM 
    FinalResults
ORDER BY 
    avg_rating DESC, num_actors DESC;
