WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year >= 2000
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(*) OVER (PARTITION BY mh.movie_id) AS link_count
    FROM 
        MovieHierarchy mh
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.link_count,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.link_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.link_count,
    COALESCE(ci.note, 'No role specified') AS casting_note,
    string_agg(DISTINCT CONCAT(an.name, ' as ', rt.role), ', ') AS cast_details
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.link_count, ci.note
ORDER BY 
    tm.link_count DESC, tm.production_year DESC;
