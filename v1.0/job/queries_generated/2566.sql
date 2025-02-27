WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.character_name) AS cast,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        (SELECT 
            m.movie_id, 
            k.keyword
         FROM 
            movie_keyword m
         JOIN 
            keyword k ON m.keyword_id = k.id) kc ON t.id = kc.movie_id
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast,
        md.keyword_count,
        RANK() OVER (ORDER BY md.keyword_count DESC, md.production_year DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast,
    rm.keyword_count,
    CASE 
        WHEN rm.keyword_count IS NULL THEN 'No keywords'
        ELSE 'Keywords found'
    END AS keyword_status
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank, rm.production_year DESC;

