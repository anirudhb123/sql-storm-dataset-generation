WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id,
        m2.title,
        m2.production_year,
        h.depth + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy h ON m.movie_id = h.movie_id
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    CAST(ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.depth) AS VARCHAR) AS rank_by_year,
    COUNT(*) OVER (PARTITION BY h.production_year) AS total_movies,
    COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_notes_count,
    STRING_AGG(DISTINCT c.note, ', ') AS distinct_cast_notes
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id AND c.movie_id = h.movie_id
WHERE 
    h.production_year >= 2000 
    AND h.production_year < 2023
    AND (h.title ILIKE '%adventure%' OR h.title ILIKE '%action%')
GROUP BY 
    h.movie_id, h.title, h.production_year, h.depth
ORDER BY 
    h.production_year DESC, h.depth, h.title;
