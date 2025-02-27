WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.person_id) AS cast_ids,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        mi.note IS NULL  -- Filtering out movies with notes
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_ids,
        md.keywords,
        CASE 
            WHEN md.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic' 
        END AS era
    FROM 
        MovieDetails md
    WHERE 
        md.title LIKE '%Adventure%'  -- Targeting movies within a specific genre
)
SELECT 
    fm.era,
    COUNT(fm.movie_id) AS movie_count,
    STRING_AGG(fm.title, ', ') AS titles,
    STRING_AGG(fm.keywords, ', ') AS all_keywords
FROM 
    FilteredMovies fm
JOIN 
    aka_name an ON POSITION(LOWER(an.name) IN LOWER(fm.cast_ids)) > 0  -- Filtering based on actor names
GROUP BY 
    fm.era;

This SQL query benchmarks string processing through the use of string functions, specifically using `LIKE`, `LOWER`, `POSITION`, and the aggregation functions `GROUP_CONCAT` and `STRING_AGG` to collect and process data related to movies, their casts, and keywords, while filtering and classifying them into modern and classic eras based on their production years.
