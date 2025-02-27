WITH RecursiveMovieStats AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_note_present,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        m.id
),
RankedMovies AS (
    SELECT 
        movie_id, 
        title,
        total_cast,
        avg_cast_note_present,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS cast_rank
    FROM 
        RecursiveMovieStats
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast > 10 THEN 'Large Cast' 
            WHEN total_cast BETWEEN 5 AND 10 THEN 'Medium Cast' 
            ELSE 'Small Cast' 
        END AS cast_size_category
    FROM 
        RankedMovies
)
SELECT 
    *,
    COALESCE(NULLIF(cast_size_category, 'Small Cast'), 'No Cast Information') AS cast_category_info,
    string_agg(DISTINCT k.keyword, ', ') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    f.avg_cast_note_present > 0.5 OR f.total_cast = 0
GROUP BY 
    f.movie_id, f.title, f.total_cast, f.avg_cast_note_present, f.cast_names, f.cast_rank, f.cast_size_category
ORDER BY 
    f.cast_rank;
