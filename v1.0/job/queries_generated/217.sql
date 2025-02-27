WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
PopularMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
),
MovieDetails AS (
    SELECT 
        pm.title,
        pm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_keyword mk ON pm.title = mk.movie_id
    GROUP BY 
        pm.title, pm.production_year, mk.keyword
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.keyword_count,
    COALESCE(SUM(ci.nr_order), 0) AS total_cast_order,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Highly Tagged'
        WHEN md.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Few Tags'
    END AS tag_status
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.title = ci.movie_id
GROUP BY 
    md.title, md.production_year, md.keyword, md.keyword_count
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
