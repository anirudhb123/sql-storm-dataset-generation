WITH RecursiveMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(e.season_nr, 0) AS season_number,
        COALESCE(e.episode_nr, 0) AS episode_number,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS seasonal_rank
    FROM
        aka_title t
    LEFT JOIN
        aka_title e ON t.episode_of_id = e.id
    WHERE
        (t.production_year IS NOT NULL OR e.production_year IS NOT NULL)
),
MovieCredits AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        name a ON ci.person_id = a.id
    JOIN
        role_type r ON ci.role_id = r.id
    JOIN
        RecursiveMovies m ON ci.movie_id = m.movie_id
    GROUP BY
        m.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.cast_names, 'No Cast') AS cast_details,
        COALESCE(k.keyword, 'No Keywords') AS keywords
    FROM
        RecursiveMovies m
    LEFT JOIN
        MovieCredits mc ON m.movie_id = mc.movie_id
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
FinalOutput AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_details,
        STRING_AGG(DISTINCT md.keywords, ', ') AS combined_keywords
    FROM
        MovieDetails md
    GROUP BY
        md.movie_id, md.title, md.production_year, md.cast_details
)
SELECT
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.cast_details,
    fo.combined_keywords,
    CASE WHEN fo.production_year < 2000 THEN 'Classic' ELSE 'Modern' END AS era,
    CASE 
        WHEN fo.cast_details = 'No Cast' THEN 'Unknown Cast'
        WHEN fo.combined_keywords IS NULL THEN 'No Keywords Available'
        ELSE 'Full Details Available'
    END AS detail_status
FROM
    FinalOutput fo
WHERE
    fo.production_year IS NOT NULL
ORDER BY
    fo.production_year DESC, 
    fo.title;
