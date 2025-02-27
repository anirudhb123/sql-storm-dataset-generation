WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.id) > 0
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year BETWEEN 2000 AND 2023
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.id) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        TopMovies tm ON t.title = tm.title AND t.production_year = tm.production_year
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    COALESCE(NULLIF(md.keywords, ''), 'No keywords') AS keywords,
    COUNT(DISTINCT ci.role_id) as unique_roles,
    STRING_AGG(DISTINCT r.role, ', ') AS roles
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    role_type r ON ci.role_id = r.id
GROUP BY 
    md.title, md.production_year, md.keyword_count, md.keywords
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
