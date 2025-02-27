
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title m 
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No keywords') AS keywords,
        COALESCE(STRING_AGG(DISTINCT ct.kind, ', '), 'No companies') AS company_types
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.total_cast, rm.cast_names
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        md.keywords,
        md.company_types,
        CASE 
            WHEN md.production_year < 2010 THEN 'Classic' 
            ELSE 'Modern' 
        END AS film_category
    FROM 
        MovieDetails md
)
SELECT 
    md.*, 
    LENGTH(md.cast_names) AS cast_names_length, 
    UPPER(md.title) AS title_uppercase 
FROM 
    FinalOutput md 
ORDER BY 
    md.total_cast DESC, 
    md.production_year ASC 
LIMIT 50;
