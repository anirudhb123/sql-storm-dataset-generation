
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY m.info_type_id DESC) AS rn,
        COALESCE(
            (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = a.id), 
            0
        ) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        a.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'movie%'
        )
    AND 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        r.keyword_count
    FROM 
        RankedMovies r
    WHERE 
        r.rn = 1 AND r.keyword_count > 0
),
CastInfoAgg AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        f.title,
        f.production_year,
        COALESCE(c.actor_count, 0) AS actor_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        CastInfoAgg c ON f.title = (SELECT title FROM aka_title WHERE id = c.movie_id LIMIT 1)
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count
FROM 
    TopMovies tm
WHERE 
    tm.actor_count >= 5
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC
LIMIT 10;
