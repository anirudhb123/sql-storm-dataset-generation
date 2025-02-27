
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_members,
        CASE 
            WHEN rm.total_cast > 5 THEN 'Ensemble Cast'
            WHEN rm.total_cast BETWEEN 3 AND 5 THEN 'Small Cast'
            ELSE 'Minimal Cast'
        END AS cast_category
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.production_year >= 2000
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.cast_members,
    fm.cast_category,
    k.keyword AS movie_keywords
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    movie_keyword AS mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC
LIMIT 10;
