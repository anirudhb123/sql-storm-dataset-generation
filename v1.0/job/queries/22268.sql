
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
popular_titles AS (
    SELECT 
        t.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS avg_notes_present,
        MAX(t.production_year) AS max_production_year
    FROM 
        ranked_titles rt
    JOIN 
        cast_info ci ON ci.movie_id = rt.title_id
    INNER JOIN 
        aka_title t ON t.id = rt.title_id
    GROUP BY 
        t.title
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
), 
title_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
), 
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(k.keywords, 'No Keywords') AS movie_keywords,
        ci.note,
        pt.cast_count,
        pt.avg_notes_present,
        pt.max_production_year
    FROM 
        aka_title t
    LEFT JOIN 
        title_keywords k ON k.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        popular_titles pt ON pt.title = t.title
    WHERE 
        pt.cast_count IS NOT NULL OR ci.note IS NOT NULL
)
SELECT 
    md.title,
    md.movie_keywords,
    md.cast_count,
    CASE 
        WHEN md.avg_notes_present > 0.5 
        THEN 'Effective Cast' 
        ELSE 'Less Effective Cast' 
    END AS cast_effectiveness,
    CASE 
        WHEN md.max_production_year IS NULL 
        THEN 'Unknown Year' 
        ELSE CAST(md.max_production_year AS VARCHAR) 
    END AS latest_year
FROM 
    movie_details md
WHERE 
    md.movie_keywords LIKE '%Action%' 
    OR md.title ILIKE '%Adventure%'
ORDER BY 
    md.cast_count DESC, md.title ASC
LIMIT 100 OFFSET 0;
