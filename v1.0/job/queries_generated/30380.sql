WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordCTE AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keywords, 'No keywords') AS keywords,
        COALESCE(c.company_count, 0) AS company_count,
        m.cast_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        KeywordCTE k ON m.movie_id = k.movie_id
    LEFT JOIN 
        CompanyCTE c ON m.movie_id = c.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_count,
    md.cast_count,
    CASE 
        WHEN md.company_count > 0 AND md.cast_count > 10 THEN 'Featured'
        WHEN md.cast_count <= 10 THEN 'Low Cast'
        ELSE 'Other'
    END AS classification
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
