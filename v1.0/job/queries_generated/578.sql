WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        ka.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ci.nr_order) AS actor_rank
    FROM
        aka_title a
    JOIN
        cast_info ci ON a.movie_id = ci.movie_id
    JOIN
        aka_name ka ON ci.person_id = ka.person_id
    WHERE
        a.production_year >= 2000
),
TopMovies AS (
    SELECT
        title,
        production_year,
        actor_name
    FROM
        RankedMovies
    WHERE
        actor_rank = 1
),
MovieKeywords AS (
    SELECT
        m.title,
        k.keyword
    FROM
        TopMovies m
    LEFT JOIN
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
MoviesWithInfo AS (
    SELECT
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COUNT(mi.info) AS info_count
    FROM
        TopMovies tm
    LEFT JOIN
        MovieKeywords mk ON tm.title = mk.title
    LEFT JOIN
        movie_info mi ON tm.title = mi.movie_id
    GROUP BY
        tm.title, tm.production_year, mk.keyword
),
FinalResults AS (
    SELECT
        *,
        CASE 
            WHEN info_count > 5 THEN 'Highly Descriptive'
            WHEN info_count BETWEEN 3 AND 5 THEN 'Moderately Descriptive'
            ELSE 'Slightly Descriptive'
        END AS descriptor_type
    FROM 
        MoviesWithInfo
)
SELECT
    fr.title,
    fr.production_year,
    fr.keyword,
    fr.descriptor_type,
    COUNT(DISTINCT ci.person_id) AS total_actors
FROM
    FinalResults fr
JOIN
    cast_info ci ON fr.title = ci.movie_id
GROUP BY
    fr.title, fr.production_year, fr.keyword, fr.descriptor_type
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    fr.production_year DESC,
    fr.keyword ASC
LIMIT 10;
