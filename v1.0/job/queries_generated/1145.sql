WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.keywords, 'No keywords available') AS keywords,
    (
        SELECT 
            COUNT(DISTINCT ci.person_id)
        FROM 
            cast_info ci
        JOIN 
            title ti ON ci.movie_id = ti.id
        WHERE 
            ti.title = tm.title
    ) AS cast_count,
    (
        SELECT 
            AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END)
        FROM 
            movie_info mi
        WHERE 
            mi.movie_id = tm.production_year
            AND mi.note IS NOT NULL
    ) AS average_note_length
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
