WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    HAVING 
        COUNT(ci.person_id) > 5 OR (COUNT(ci.person_id) IS NULL AND t.production_year < 2000)
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keyword,
        md.total_cast,
        md.cast_names,
        md.rn,
        COALESCE(NULLIF(md.keyword, ''), 'No keywords') AS display_keyword,
        CASE 
            WHEN md.total_cast > 10 THEN 'Large Cast'
            WHEN md.total_cast BETWEEN 6 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        MovieDetails md
),
CurrentYearMovies AS (
    SELECT 
        movie_title,
        production_year,
        keyword,
        total_cast,
        cast_names,
        cast_size
    FROM 
        RankedMovies
    WHERE 
        production_year = EXTRACT(YEAR FROM cast('2024-10-01' as date))
),
DistinctYears AS (
    SELECT DISTINCT 
        production_year
    FROM 
        RankedMovies
)
SELECT 
    r.movie_title,
    r.production_year,
    r.keyword,
    r.total_cast,
    r.cast_names,
    r.cast_size,
    CASE 
        WHEN r.rn IS NOT NULL AND r.production_year IN (SELECT production_year FROM DistinctYears) THEN 'Featured in Current Year'
        ELSE 'Classic'
    END AS movie_category
FROM 
    RankedMovies r
LEFT JOIN 
    CurrentYearMovies cy ON r.movie_title = cy.movie_title
ORDER BY 
    r.production_year DESC, 
    r.total_cast DESC;