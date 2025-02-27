WITH MovieStats AS (
    SELECT
        a.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(mi.info::numeric) AS avg_rating,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE
        a.production_year IS NOT NULL
        AND a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY
        a.id
),
HighRankedMovies AS (
    SELECT 
        movie_title,
        actor_count,
        avg_rating,
        actors
    FROM 
        MovieStats
    WHERE
        rank <= 5
)
SELECT 
    h.movie_title,
    h.actor_count,
    COALESCE(h.avg_rating::text, 'Not Rated') AS avg_rating,
    h.actors,
    CASE 
        WHEN h.actor_count > 15 THEN 'Highly Casted'
        WHEN h.actor_count BETWEEN 10 AND 15 THEN 'Moderately Casted'
        ELSE 'Light Casted'
    END AS cast_level
FROM 
    HighRankedMovies h
ORDER BY 
    h.avg_rating DESC NULLS LAST;
