
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeyMovieInfo AS (
    SELECT 
        mw.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        MAX(CASE WHEN i.info_type_id = 1 THEN i.info END) AS summary
    FROM 
        movie_keyword mw
    JOIN 
        keyword k ON mw.keyword_id = k.id
    JOIN 
        movie_info i ON mw.movie_id = i.movie_id
    GROUP BY 
        mw.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.rank_by_cast_count,
    k.keywords,
    COALESCE(k.summary, 'No summary available') AS movie_summary
FROM 
    RankedMovies r
LEFT JOIN 
    KeyMovieInfo k ON r.movie_id = k.movie_id
WHERE 
    r.rank_by_cast_count <= 5
ORDER BY 
    r.production_year DESC, 
    r.rank_by_cast_count ASC;
