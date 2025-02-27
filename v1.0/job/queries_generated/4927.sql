WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) as rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
), 
TopMovies AS (
    SELECT 
        title, production_year, cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(p.info, 'No Info') AS person_info
    FROM 
        TopMovies t
    LEFT JOIN 
        MovieKeywords k ON t.id = k.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info p ON mi.info_type_id = p.info_type_id
)

SELECT 
    md.title,
    md.production_year,
    md.keyword,
    STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
    COUNT(DISTINCT m.company_id) AS production_companies,
    MAX(CASE WHEN c.kind IS NULL THEN 'Unknown' ELSE c.kind END) AS company_type
FROM 
    MovieDetails md
LEFT JOIN 
    complete_cast cc ON md.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    company_name m ON ci.movie_id = m.id
LEFT JOIN 
    company_type c ON m.id = c.id
GROUP BY 
    md.title, md.production_year, md.keyword
ORDER BY 
    md.production_year DESC, COUNT(DISTINCT p.name) DESC;
