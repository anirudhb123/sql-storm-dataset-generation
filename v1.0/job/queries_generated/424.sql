WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
ExpandedCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN r.role = 'Actor' THEN 1 ELSE 0 END) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ec.total_cast, 0) AS total_cast,
    COALESCE(ec.actor_count, 0) AS actor_count,
    COALESCE(ks.keywords_list, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.title_rank = 1 THEN 'First Title of Year'
        ELSE 'Other Titles'
    END AS title_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ExpandedCast ec ON rm.movie_id = ec.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.title_rank;
