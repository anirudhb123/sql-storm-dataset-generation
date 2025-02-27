WITH movie_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        MAX(CASE WHEN m.production_year < 2000 THEN 'Classic' ELSE 'Modern' END) AS era
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
ranking_movie AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keyword_count,
        era,
        RANK() OVER (PARTITION BY era ORDER BY cast_count DESC) as cast_rank
    FROM 
        movie_summary
),
recent_movies AS (
    SELECT 
        title, 
        production_year,
        MAX(cast_count) OVER (PARTITION BY production_year) AS max_cast_count
    FROM 
        ranking_movie
    WHERE 
        production_year >= 2010
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    rm.keyword_count,
    (CASE 
        WHEN rm.cast_count = rm.max_cast_count 
        THEN 'Top Cast' 
        ELSE 'Regular' 
    END) AS cast_status,
    COALESCE(rm.era, 'Unknown') AS era_label
FROM 
    ranking_movie rm
JOIN 
    recent_movies r ON rm.title = r.title AND rm.production_year = r.production_year
WHERE 
    rm.cast_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_rank;
