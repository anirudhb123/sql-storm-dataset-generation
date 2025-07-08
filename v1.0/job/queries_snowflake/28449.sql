
WITH MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
Top10Movies AS (
    SELECT 
        mv.id AS movie_id,
        mv.title AS movie_title,
        mv.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        title mv
    LEFT JOIN 
        MovieKeywordCounts mkc ON mv.id = mkc.movie_id
    WHERE 
        mv.production_year BETWEEN 1990 AND 2020
    ORDER BY 
        keyword_count DESC
    LIMIT 10
),
MovieCast AS (
    SELECT 
        tc.movie_id,
        COUNT(c.id) AS cast_member_count
    FROM 
        cast_info c
    JOIN 
        Top10Movies tc ON c.movie_id = tc.movie_id
    GROUP BY 
        tc.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT mi.info) AS infos
    FROM 
        movie_info mi 
    JOIN 
        Top10Movies m ON mi.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    t.movie_id,
    t.movie_title,
    t.production_year,
    COALESCE(mc.cast_member_count, 0) AS cast_member_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    mi.infos
FROM 
    Top10Movies t
LEFT JOIN 
    MovieCast mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywordCounts mkc ON t.movie_id = mkc.movie_id
LEFT JOIN 
    MovieInfo mi ON t.movie_id = mi.movie_id
ORDER BY 
    keyword_count DESC, t.production_year DESC;
