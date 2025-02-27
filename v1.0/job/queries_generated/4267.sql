WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY mt.id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year BETWEEN 1990 AND 2020
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        title_rank,
        company_count
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(CAST(COUNT(DISTINCT ci.person_id) AS int), 0) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    CASE 
        WHEN md.cast_count IS NULL THEN 'No cast information'
        WHEN md.cast_count > 0 THEN 'Has cast information'
        ELSE 'No cast information'
    END AS cast_info_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;
