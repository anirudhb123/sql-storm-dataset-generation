
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.aka_names,
    COALESCE(mi.info, 'N/A') AS additional_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' FETCH FIRST 1 ROWS ONLY)
ORDER BY 
    fm.production_year DESC;
