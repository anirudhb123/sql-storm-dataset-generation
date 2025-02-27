WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT k.id) AS keyword_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_rating,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast_count
    FROM
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
RecommendedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_rating,
        rm.ordered_cast_count,
        CASE 
            WHEN rm.keyword_count > 5 AND rm.cast_rating > 0.5 THEN 'Highly Recommended'
            WHEN rm.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Recommended'
            ELSE 'Low Recommendation'
        END AS recommendation
    FROM
        RankedMovies rm
    WHERE
        rm.production_year >= 2000
    ORDER BY
        rm.cast_rating DESC, rm.keyword_count DESC
)
SELECT
    rm.title,
    rm.production_year,
    rm.recommendation,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    string_agg(DISTINCT a.name, ', ') AS main_cast_names
FROM
    RecommendedMovies rm
LEFT JOIN
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    aka_name a ON ci.person_id = a.person_id
GROUP BY
    rm.movie_id, rm.title, rm.production_year, rm.recommendation
ORDER BY
    rm.production_year DESC, total_cast DESC;
