WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.title, t.production_year
),
PopularActors AS (
    SELECT
        ak.name,
        ak.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    WHERE
        ak.name IS NOT NULL
    GROUP BY
        ak.name, ak.person_id
    HAVING
        COUNT(DISTINCT ci.movie_id) >= 5
),
MoviesWithKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY
        mt.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    rm.num_cast,
    ak.name AS popular_actor,
    COALESCE(mkw.keywords, 'No keywords') AS keywords,
    CASE
        WHEN rm.num_cast > 10 THEN 'A' 
        WHEN rm.num_cast BETWEEN 5 AND 10 THEN 'B'
        ELSE 'C' 
    END AS cast_category,
    FIRST_VALUE(ak.person_id) OVER (PARTITION BY rm.production_year ORDER BY ak.movie_count DESC) AS first_popular_actor_id,
    COUNT(DISTINCT ci.movie_id) OVER (PARTITION BY rm.production_year) AS total_movies_year
FROM
    RankedMovies rm
LEFT JOIN
    PopularActors ak ON rm.rank <= 10
LEFT JOIN
    MoviesWithKeywords mkw ON rm.title = mkw.movie_id
LEFT JOIN
    cast_info ci ON rm.title = ci.movie_id
WHERE
    (ak.name IS NOT NULL OR ak.person_id IS NULL)
    AND (rm.production_year > 2000 OR rm.num_cast IS NULL)
ORDER BY
    rm.production_year DESC, rm.num_cast DESC;
