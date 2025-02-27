WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
),
KeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
FinalBenchmark AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        kc.keyword_count,
        CASE 
            WHEN kc.keyword_count IS NULL THEN 'No Keywords'
            ELSE 'Has Keywords'
        END AS keyword_status
    FROM 
        TopMovies tm
    LEFT JOIN 
        KeywordCounts kc ON tm.movie_id = kc.movie_id
    WHERE 
        tm.rank <= 10
)

SELECT 
    fb.title,
    fb.production_year,
    fb.cast_count,
    COALESCE(fb.keyword_count, 0) AS keyword_count,
    fb.keyword_status
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.cast_count DESC, fb.title ASC;
