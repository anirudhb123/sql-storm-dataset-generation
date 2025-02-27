
WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(COUNT(ci.person_id), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END), 0) AS valid_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        valid_cast_count,
        NTILE(10) OVER (ORDER BY production_year DESC) AS decade_bucket
    FROM 
        RecursiveMovieCTE
    WHERE 
        production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        fi.info AS additional_info,
        vi.note AS info_note
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info fi ON mt.id = fi.movie_id
    LEFT JOIN 
        movie_info_idx vi ON mt.id = vi.movie_id AND fi.info_type_id = vi.info_type_id
)
SELECT 
    fl.title AS movie_title,
    fl.production_year,
    fl.cast_count,
    fl.valid_cast_count,
    COALESCE(mg.genres, 'No Genre') AS genre_list,
    mi.additional_info,
    mi.info_note,
    CASE 
        WHEN fl.cast_count > 100 THEN 'Large Ensemble'
        WHEN fl.cast_count BETWEEN 50 AND 100 THEN 'Medium Ensemble'
        ELSE 'Small Ensemble'
    END AS cast_size_category
FROM 
    FilteredMovies fl
LEFT JOIN 
    MovieGenres mg ON fl.title_id = mg.movie_id
LEFT JOIN 
    MovieInfo mi ON fl.title_id = mi.movie_id
WHERE 
    (fl.production_year >= 1990 OR fl.production_year IS NULL)
AND 
    (fl.cast_count IS NOT NULL OR fl.valid_cast_count IS NOT NULL)
ORDER BY 
    fl.production_year DESC, 
    fl.cast_count DESC;
