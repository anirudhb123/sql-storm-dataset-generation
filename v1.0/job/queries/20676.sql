WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(*) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfoCTE AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info available') AS movie_info,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 'Note exists' ELSE 'No note' END) AS note_existence
    FROM 
        aka_title m
    LEFT OUTER JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, mi.info
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count = 1
),
UnionedTitles AS (
    SELECT 
        title_id, title, production_year
    FROM 
        FilteredMovies
    UNION ALL
    SELECT 
        -1 AS title_id, 'Unknown Movie' AS title, 1900 AS production_year
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    COALESCE(mi.movie_info, 'No additional info') AS additional_info,
    f_total.total_cast,
    f_total.note_existence
FROM 
    UnionedTitles f
LEFT JOIN 
    MovieInfoCTE mi ON f.title_id = mi.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        SUM(total_cast) AS total_cast,
        STRING_AGG(note_existence, ', ') AS note_existence
    FROM 
        MovieInfoCTE
    GROUP BY 
        movie_id
) f_total ON f.title_id = f_total.movie_id
WHERE 
    (f.title_id IS NULL OR f.title_id != -1)
ORDER BY 
    f.production_year DESC, f.title;
