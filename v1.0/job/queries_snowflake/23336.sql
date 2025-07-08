
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5
),
average_cast AS (
    SELECT 
        ci.movie_id,
        AVG(CASE 
            WHEN ci.note IS NULL THEN 0 
            ELSE LENGTH(ci.note) - LENGTH(REPLACE(ci.note, ' ', '')) + 1 
            END) AS average_word_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
ranked_titles AS (
    SELECT 
        h.movie_id,
        h.title,
        h.depth,
        ROW_NUMBER() OVER (PARTITION BY h.depth ORDER BY h.title ASC) AS rank
    FROM 
        movie_hierarchy h
)
SELECT 
    rt.title,
    rt.depth,
    ac.average_word_count,
    CASE 
        WHEN ac.average_word_count IS NULL THEN 'No Cast Information'
        WHEN ac.average_word_count > 5 THEN 'Rich Cast Notes'
        ELSE 'Sparse Cast Notes'
    END AS cast_quality,
    COUNT(DISTINCT mi.info_type_id) AS unique_info_types,
    LISTAGG(DISTINCT ci.note, ', ') WITHIN GROUP (ORDER BY ci.note) AS cast_notes
FROM 
    ranked_titles rt
LEFT JOIN 
    average_cast ac ON rt.movie_id = ac.movie_id
LEFT JOIN 
    cast_info ci ON rt.movie_id = ci.movie_id
LEFT JOIN 
    movie_info mi ON rt.movie_id = mi.movie_id
WHERE 
    rt.depth <= 3 AND 
    (ac.average_word_count IS NOT NULL OR rt.depth = 1)
GROUP BY 
    rt.title, rt.depth, ac.average_word_count
HAVING 
    COUNT(DISTINCT mi.info_type_id) < 10
ORDER BY 
    rt.depth, rt.title;
