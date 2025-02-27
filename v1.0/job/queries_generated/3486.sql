WITH RankedMovies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year
    FROM
        aka_title a
    WHERE
        a.production_year IS NOT NULL
),
ActorCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
MovieGenres AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM
        movie_keyword mt
    JOIN
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY
        mt.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    rg.genres,
    CASE
        WHEN rm.rank_by_year <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS movie_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.id = ac.movie_id
LEFT JOIN 
    MovieGenres rg ON rm.id = rg.movie_id
WHERE 
    rm.production_year > 2000 AND 
    (rg.genres IS NULL OR rg.genres LIKE '%Drama%') 
ORDER BY 
    rm.production_year DESC, movie_title;
