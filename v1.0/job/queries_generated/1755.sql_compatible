
WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(SUM(CASE WHEN r.role = 'actor' THEN 1 ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN r.role = 'director' THEN 1 ELSE 0 END), 0) AS director_count,
        COALESCE(SUM(CASE WHEN r.role = 'writer' THEN 1 ELSE 0 END), 0) AS writer_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
RankedMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.actor_count,
        ms.director_count,
        ms.writer_count,
        ms.keyword_count,
        RANK() OVER (ORDER BY ms.actor_count DESC, ms.keyword_count DESC) AS movie_rank
    FROM 
        MovieStats ms
    WHERE 
        ms.actor_count > 0
)
SELECT 
    rm.title,
    rm.actor_count,
    rm.director_count,
    rm.writer_count,
    rm.keyword_count,
    CASE 
        WHEN rm.director_count = 0 THEN 'No Director'
        ELSE 'Has Director'
    END AS director_status,
    CASE 
        WHEN rm.writer_count IS NULL THEN 'Unknown Writer'
        ELSE CAST(rm.writer_count AS VARCHAR)
    END AS writer_status
FROM 
    RankedMovies rm
WHERE 
    rm.movie_rank <= 10
ORDER BY 
    rm.movie_rank;
