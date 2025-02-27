WITH RecursiveMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = mt.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RecursiveMovies
),
FilteredMovies AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year,
        tm.cast_count
    FROM 
        TopMovies tm
    WHERE 
        tm.rank <= 10 OR (tm.production_year >= 2000 AND tm.cast_count > 5)
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        FilteredMovies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ci.note, 'No Note') AS cast_note,
    CASE
        WHEN f.production_year < 1990 THEN 'Classic'
        WHEN f.production_year BETWEEN 1990 AND 2000 THEN '90s Hit'
        ELSE 'Modern'
    END AS era,
    (SELECT COUNT(*)
     FROM movie_info mi
     WHERE mi.movie_id = f.movie_id
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    ) AS rating_count
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info mi ON f.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = f.movie_id
LEFT JOIN 
    MovieKeywords mk ON f.movie_id = mk.movie_id
WHERE 
    (f.cast_count IS NOT NULL AND f.cast_count > 0)
    OR (f.production_year IS NULL) -- This includes a bizarre condition simulating a corner case
ORDER BY 
    f.cast_count DESC, f.production_year DESC;
