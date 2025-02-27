WITH RecursiveMovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mt.id, mt.title, mt.production_year
),

RankedMovies AS (
    SELECT
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast,
        LEAD(production_year) OVER (ORDER BY production_year) AS next_year
    FROM
        RecursiveMovieCTE
    WHERE
        production_year IS NOT NULL
),

MoviesDifference AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank_by_cast,
        COALESCE(rm.next_year - rm.production_year, 0) AS year_difference,
        CASE
            WHEN rm.production_year IS NULL THEN 'No Year'
            ELSE 'Has Year'
        END AS year_status,
        CASE
            WHEN rm.rank_by_cast IS NOT NULL THEN 'Ranked'
            ELSE 'Unranked'
        END AS rank_status
    FROM
        RankedMovies rm
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.rank_by_cast,
    md.year_difference,
    md.year_status,
    md.rank_status,
    COALESCE(MISSING_LINK.linked_movie_id, 0) AS linked_movie,
    'Obtained on ' || CURRENT_DATE || ' at ' || CURRENT_TIME AS query_time,
    CASE
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM
    MoviesDifference md
LEFT JOIN 
    movie_link ml ON md.movie_id = ml.movie_id
LEFT JOIN 
    movie_link MISSING_LINK ON md.movie_id = MISSING_LINK.movie_id AND MISSING_LINK.link_type_id IS NULL
WHERE
    (md.rank_by_cast <= 5 OR md.year_difference >= 10)
    AND md.year_status = 'Has Year'
ORDER BY
    md.rank_by_cast ASC,
    md.year_difference DESC
LIMIT 50;
