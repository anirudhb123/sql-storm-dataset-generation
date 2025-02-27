WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank,
        COUNT(c.id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT *,
           CASE 
               WHEN cast_count > 10 THEN 'Large Cast'
               ELSE 'Small Cast'
           END AS cast_size
    FROM RankedMovies
    WHERE rank <= 5
),
MovieDetails AS (
    SELECT 
        fm.title,
        fm.production_year,
        THU.CAPTURE,
        fm.cast_size,
        COALESCE(CAST(NULLIF(mk.keyword, '') AS text), 'No Keywords') AS movie_keyword
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON fm.id = mk.movie_id
    RIGHT JOIN 
        (SELECT DISTINCT ON (mk.movie_id) mk.keyword, mk.movie_id
         FROM movie_keyword mk
         WHERE mk.keyword IS NOT NULL
         ORDER BY mk.movie_id, LENGTH(mk.keyword) DESC) AS THU ON fm.id = THU.movie_id
    WHERE 
        (fm.production_year BETWEEN 2000 AND 2023 OR fm.cast_size = 'Large Cast')
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_size,
        md.movie_keyword,
        COALESCE(mt.kind, 'Unknown') AS movie_kind
    FROM 
        MovieDetails md
    LEFT JOIN 
        kind_type mt ON md.kind_id = mt.id
    WHERE 
        md.cast_size = 'Large Cast' OR (md.movie_keyword <> 'No Keywords' AND md.production_year < 2020)
)
SELECT 
    FR.title,
    FR.production_year,
    FR.cast_size,
    COUNT(*) OVER (PARTITION BY FR.production_year) AS year_count,
    CONCAT(FR.title, ' - ', COALESCE(FR.movie_kind, ''), ' - ', COALESCE(FR.movie_keyword, '')) AS full_description
FROM 
    FinalResults FR
ORDER BY 
    FR.production_year DESC, 
    FR.title
OFFSET 5 ROWS 
FETCH NEXT 10 ROWS ONLY;
