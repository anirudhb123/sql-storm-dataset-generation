WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.total_cast,
        rm.aka_names,
        COALESCE(mk.keyword, 'No Keywords') AS movie_keywords,
        c.kind AS company_type,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    WHERE 
        rm.total_cast >= 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.aka_names,
    string_agg(DISTINCT fm.movie_keywords, ', ') AS keywords,
    string_agg(DISTINCT fm.company_type, ', ') AS companies,
    string_agg(DISTINCT fm.movie_info, ', ') AS additional_info
FROM 
    FilteredMovies fm
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_cast, fm.aka_names
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC;
