WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS with_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    cs.total_cast,
    cs.with_roles,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    RANK() OVER (ORDER BY m.production_year DESC, cs.total_cast DESC) AS movie_rank
FROM 
    RankedMovies m
LEFT JOIN 
    CastStats cs ON m.movie_id = cs.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) ks ON m.movie_id = ks.movie_id
WHERE 
    cs.total_cast IS NOT NULL OR cs.with_roles > 0
ORDER BY 
    movie_rank;
