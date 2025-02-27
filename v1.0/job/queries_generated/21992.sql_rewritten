WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.id) AS cast_ids,
        COUNT(DISTINCT c.id) AS cast_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count, keyword_count, year_rank
    FROM 
        RecursiveMovieCTE
    WHERE 
        year_rank <= 5 
        AND cast_count > 0
),
MoviesWithInfo AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        fm.keyword_count,
        COALESCE(mi.info, 'No additional info') AS additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON mi.movie_id = fm.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.cast_count,
    mw.keyword_count,
    mw.additional_info,
    COUNT(DISTINCT mc.id) AS production_companies,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_presence_ratio,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    MoviesWithInfo mw
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mw.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = mw.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mw.movie_id
GROUP BY 
    mw.movie_id, mw.title, mw.production_year, mw.cast_count, 
    mw.keyword_count, mw.additional_info
HAVING 
    COUNT(DISTINCT mc.id) > 1 
ORDER BY 
    mw.production_year DESC, 
    mw.cast_count DESC;