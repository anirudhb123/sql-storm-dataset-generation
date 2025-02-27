WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size,
        (SELECT COUNT(DISTINCT c1.person_id)
         FROM cast_info c1
         WHERE c1.movie_id = t.id AND c1.note IS NULL) AS null_notes_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(rm.rank_by_cast_size, 0) AS rank_by_cast_size,
        COALESCE(rm.null_notes_count, 0) AS null_notes_count,
        CASE
            WHEN t.kind_id IS NOT NULL THEN gt.kind
            ELSE 'Unknown'
        END AS genre
    FROM
        RankedMovies rm
    LEFT JOIN 
        aka_title t ON t.id = rm.movie_id
    LEFT JOIN 
        kind_type gt ON t.kind_id = gt.id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.rank_by_cast_size,
        md.null_notes_count,
        md.genre
    FROM 
        MovieDetails md
    WHERE 
        md.rank_by_cast_size <= 10
),
KeywordsCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        TopMovies tm ON mk.movie_id = tm.movie_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.rank_by_cast_size,
    tm.null_notes_count,
    kc.keyword_count,
    CASE 
        WHEN kc.keyword_count IS NULL THEN 'No Keywords' 
        WHEN kc.keyword_count > 5 THEN 'Many Keywords' 
        ELSE 'Few Keywords' 
    END AS keyword_description
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordsCounts kc ON tm.movie_id = kc.movie_id
ORDER BY 
    tm.rank_by_cast_size DESC, 
    tm.null_notes_count ASC,
    tm.production_year DESC;