WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(CAST(AVG(CASE WHEN cf.kind = 'movie' THEN 1 ELSE 0 END) AS FLOAT), 0) AS average_companies,
        RANK() OVER (ORDER BY t.production_year) as year_rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type cf ON mc.company_type_id = cf.id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.average_companies,
    rm.keyword_count,
    (SELECT 
        COUNT(DISTINCT ci.person_id)
     FROM 
        cast_info ci
     WHERE 
        ci.movie_id = (SELECT id FROM title WHERE title = md.title LIMIT 1)
    ) AS unique_cast_count,
    STRING_AGG(aka.name, ', ') AS aliases
FROM 
    MovieDetails md
LEFT JOIN 
    RankedMovies rm ON md.title = rm.title AND md.production_year = rm.production_year AND rm.rank <= 3
LEFT JOIN 
    aka_title aka ON aka.movie_id = (SELECT id FROM title WHERE title = md.title LIMIT 1)
GROUP BY 
    md.title, md.production_year, md.average_companies, rm.keyword_count
HAVING 
    md.average_companies > 0 OR rm.keyword_count IS NOT NULL;
