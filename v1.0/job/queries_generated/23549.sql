WITH RankedMovies AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        mt.id AS movie_id,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS cast_count_rank
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY
        mt.title, mt.production_year, mt.id
),
HighCastMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count_rank = 1
),
MovieKeywords AS (
    SELECT
        m.title AS movie_title,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesWithKeywords AS (
    SELECT 
        hcm.movie_title,
        hcm.production_year,
        string_agg(mk.movie_keyword, ', ') AS keywords
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        MovieKeywords mk ON hcm.movie_id = mk.movie_id
    GROUP BY 
        hcm.movie_title, hcm.production_year
),
TopMovies AS (
    SELECT
        mwk.movie_title,
        mwk.production_year,
        mwk.keywords,
        CASE
            WHEN mwk.keywords IS NULL THEN 'No Keywords'
            ELSE mwk.keywords
        END AS processed_keywords
    FROM 
        MoviesWithKeywords mwk
),
FinalResults AS (
    SELECT
        tm.movie_title,
        tm.production_year,
        tm.processed_keywords,
        COUNT(DISTINCT ci.person_id) AS unique_actors_count,
        COUNT(ci.id) AS total_roles
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    GROUP BY 
        tm.movie_title, tm.production_year, tm.processed_keywords
)
SELECT
    *,
    CASE 
        WHEN unique_actors_count > 5 THEN 'Popular'
        WHEN unique_actors_count IS NULL THEN 'Unknown'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    FinalResults
WHERE 
    processed_keywords IS NOT NULL
ORDER BY 
    production_year DESC, unique_actors_count DESC
LIMIT 10;
