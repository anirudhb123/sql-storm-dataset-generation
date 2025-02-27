WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PopularMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalReport AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(pm.cast_count, 0) AS cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN rm.total_movies = 0 THEN 'No Movies Yet for this Year'
            ELSE ROUND((100.0 * ROW_NUMBER() OVER (ORDER BY rm.rn)) / rm.total_movies, 2) || '%' 
        END AS percentage_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularMovies pm ON rm.id = pm.id
    LEFT JOIN 
        MovieKeywords mk ON pm.id = mk.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    title,
    production_year,
    cast_count,
    keywords,
    percentage_rank
FROM 
    FinalReport
WHERE 
    cast_count > 0
ORDER BY 
    production_year DESC, cast_count DESC, title;
