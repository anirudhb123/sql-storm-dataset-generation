
WITH movie_stats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT c.note, ', ') AS cast_notes,
        COALESCE(SUM(CASE WHEN mi.info ILIKE '%Oscar%' THEN 1 ELSE 0 END), 0) AS oscar_count, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award')
    GROUP BY 
        t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.cast_notes
    FROM 
        movie_stats ms
    WHERE 
        ms.cast_count > (SELECT AVG(cast_count) FROM movie_stats)
),
bizarre_movie_links AS (
    SELECT 
        m1.id AS movie_id,
        m1.title AS linked_movie_title,
        ml.linked_movie_id AS linked_movie_id,
        t.title AS original_linked_title
    FROM 
        title m1
    INNER JOIN 
        movie_link ml ON m1.id = ml.movie_id
    INNER JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        m1.production_year = (SELECT MAX(production_year) FROM title WHERE title LIKE '%Adventures%') 
        AND t.kind_id IS NOT NULL
)
SELECT 
    hcm.movie_id,
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    hcm.cast_notes,
    bml.linked_movie_title,
    bml.linked_movie_id,
    bml.original_linked_title
FROM 
    high_cast_movies hcm
LEFT JOIN 
    bizarre_movie_links bml ON hcm.movie_id = bml.movie_id
WHERE 
    hcm.production_year IS NOT NULL
    AND hcm.cast_notes IS NOT NULL
ORDER BY 
    hcm.cast_count DESC, hcm.production_year ASC
LIMIT 100;
