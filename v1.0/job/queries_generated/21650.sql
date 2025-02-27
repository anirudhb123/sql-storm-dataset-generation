WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
MovieGenres AS (
    SELECT 
        t.id AS movie_id,
        k.keyword AS genre
    FROM 
        aka_title t
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
),
FullMovieInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        STRING_AGG(DISTINCT mg.genre, ', ') AS genres
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieGenres mg ON mg.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year, tm.cast_count
),
DetailedMovieInfo AS (
    SELECT 
        f.title,
        f.production_year,
        f.cast_count,
        f.genres,
        COALESCE(mci.info, 'No additional info available') AS additional_info,
        ROW_NUMBER() OVER (PARTITION BY f.production_year ORDER BY f.cast_count DESC) AS yearly_rank
    FROM 
        FullMovieInfo f
    LEFT JOIN 
        movie_info mci ON (SELECT id FROM aka_title WHERE title = f.title LIMIT 1) = mci.movie_id 
                      AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
)
SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.genres,
    d.additional_info,
    CASE 
        WHEN d.yearly_rank IS NULL THEN 'Unknown Rank'
        ELSE d.yearly_rank::TEXT
    END AS rank_description
FROM 
    DetailedMovieInfo d
WHERE 
    d.yearly_rank IS NOT NULL OR d.additional_info IS NOT NULL
ORDER BY 
    d.production_year DESC, d.cast_count DESC;
