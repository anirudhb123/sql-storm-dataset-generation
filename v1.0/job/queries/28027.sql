WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ci.note, ', ') AS role_notes
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        * 
    FROM 
        MovieDetails
    WHERE 
        cast_count > 3 
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    fm.cast_count,
    fm.role_notes
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, fm.title;