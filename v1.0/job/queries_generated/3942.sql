WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
StudentAggregates AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.title,
        md.production_year,
        sa.total_cast,
        sa.cast_names,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    JOIN 
        StudentAggregates sa ON md.title_id = sa.movie_id
    WHERE 
        sa.total_cast > 5
    GROUP BY 
        md.title_id, md.title, md.production_year, sa.total_cast, sa.cast_names
)
SELECT 
    fb.*,
    CASE 
        WHEN fb.production_year < 2000 THEN 'Classic'
        WHEN fb.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COALESCE(NULLIF(fb.cast_names, ''), 'Unknown Cast') AS final_cast_names
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.total_cast DESC;
