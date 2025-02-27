WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        coalesce(k.keyword, 'No Keyword') AS keyword,
        string_agg(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
RankedMovies AS (
    SELECT 
        md.*,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.cast_names,
    rm.cast_count,
    CASE 
        WHEN rm.rank_within_year <= 5 THEN 'Top 5'
        WHEN rm.rank_within_year <= 10 THEN 'Top 10'
        ELSE 'Others' 
    END AS rank_category
FROM 
    RankedMovies rm
WHERE 
    rm.production_year IS NOT NULL
    AND rm.cast_count > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
