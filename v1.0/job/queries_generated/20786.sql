WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_within_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        rank_within_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 10  -- Top 10 movies each year
),
MovieCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_details
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(mi.info) AS genre,
        COUNT(*) AS keyword_count
    FROM 
        movie_info m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        m.movie_id
),
CombinedData AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        mc.cast_details,
        mi.genre,
        mi.keyword_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        MovieCast mc ON f.movie_id = mc.movie_id
    LEFT JOIN 
        MovieInfo mi ON f.movie_id = mi.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    COALESCE(cd.production_year::TEXT, 'Unknown') AS prod_year,
    COALESCE(cd.cast_details, 'No Cast Available') AS cast,
    COALESCE(cd.genre, 'Unknown Genre') AS genre,
    CASE 
        WHEN cd.keyword_count IS NULL THEN 0
        ELSE cd.keyword_count 
    END AS kw_count
FROM 
    CombinedData cd
WHERE 
    cd.production_year IS NOT NULL OR cd.cast_details IS NOT NULL
ORDER BY 
    cd.production_year DESC, 
    cd.title ASC;

-- Additional checks for NULL logic and unusual semantics:
SELECT 
    COUNT(*) AS empty_genre_count,
    COUNT(CASE WHEN genre IS NULL THEN 1 END) AS null_genre_count,
    COUNT(*) OVER () AS total_movies
FROM 
    CombinedData
WHERE 
    genre IS NULL
    OR keyword_count IS NULL
    OR production_year IS NULL;

-- Test case for a LEFT JOIN where both sides may be NULL
SELECT 
    c.movie_id AS left_movie_id, 
    m.id AS right_movie_id,
    COALESCE(c.cast_details, 'Unknown Cast') AS cast_details
FROM 
    MovieCast c 
FULL OUTER JOIN 
    MovieInfo m ON c.movie_id = m.movie_id
WHERE 
    c.cast_details IS NULL OR m.genre IS NULL;

-- Demonstrating bizarre SQL semantic with JSON
SELECT 
    json_agg(row_to_json(cd.*)) AS movie_data
FROM 
    CombinedData cd
WHERE 
    cd.keyword_count > 5 
    AND (cd.genre LIKE '%Drama%' OR cd.genre IS NULL);
