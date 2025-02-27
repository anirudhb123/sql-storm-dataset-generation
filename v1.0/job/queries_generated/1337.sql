WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        RankedMovies mv
    LEFT JOIN 
        cast_info c ON mv.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mv.movie_id = mk.movie_id
    GROUP BY 
        mv.movie_id, mv.title, mv.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_names,
        keyword_count,
        CASE 
            WHEN keyword_count > 5 THEN 'High'
            WHEN keyword_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS keyword_density
    FROM 
        MovieDetails
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_names,
    m.keyword_density,
    COALESCE(ca.kind, 'N/A') AS company_type
FROM 
    FilteredMovies m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type ca ON mc.company_type_id = ca.id
WHERE 
    m.keyword_density = 'High'
ORDER BY 
    m.production_year DESC, m.title;
