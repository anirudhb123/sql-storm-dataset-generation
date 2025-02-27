
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
HighlyRatedMovies AS (
    SELECT 
        m.movie_id,
        m.info AS rating
    FROM 
        movie_info m
    INNER JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info = 'rating' AND
        CAST(m.info AS FLOAT) >= 8.0
),
TitleWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mt
    INNER JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(hm.rating, 'N/A') AS rating,
    COALESCE(tw.keywords, 'None') AS keywords
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCount ac ON r.movie_id = ac.movie_id
LEFT JOIN 
    HighlyRatedMovies hm ON r.movie_id = hm.movie_id
LEFT JOIN 
    TitleWithKeywords tw ON r.movie_id = tw.movie_id
WHERE 
    r.rank_per_year <= 5
GROUP BY
    r.movie_id,
    r.title,
    r.production_year,
    ac.actor_count,
    hm.rating,
    tw.keywords
ORDER BY 
    r.production_year DESC, 
    actor_count DESC,
    rating DESC NULLS LAST;
