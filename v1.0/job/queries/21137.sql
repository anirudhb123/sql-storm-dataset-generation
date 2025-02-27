
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_cast_order,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year
), 
MovieKeywordDetails AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
), 
FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        md.avg_cast_order,
        md.actor_names,
        COALESCE(mkd.keyword_count, 0) AS keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieKeywordDetails mkd ON md.title = (SELECT title FROM aka_title WHERE id = mkd.movie_id)
    WHERE 
        (md.production_year BETWEEN 2000 AND 2023) 
        AND (md.avg_cast_order IS NOT NULL OR COALESCE(mkd.keyword_count, 0) > 5)
)

SELECT 
    title,
    production_year,
    total_cast,
    avg_cast_order,
    actor_names,
    keyword_count,
    CASE 
        WHEN total_cast = 0 THEN 'No Cast'
        WHEN total_cast BETWEEN 1 AND 5 THEN 'Few Cast'
        WHEN total_cast > 5 AND keyword_count = 0 THEN 'Many Cast - No Keywords'
        ELSE 'Many Cast'
    END AS cast_category
FROM 
    FilteredMovies
ORDER BY 
    total_cast DESC,
    avg_cast_order ASC
LIMIT 50;
