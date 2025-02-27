WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
SubqueryTitleIndustry AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        m.movie_id
),
CrossJoinKeywords AS (
    SELECT 
        k.keyword,
        t.title
    FROM 
        keyword k
    JOIN 
        aka_title t ON k.id = t.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Comedy%')
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        COALESCE(kw.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(kw.keyword, 'No Keywords') AS keyword,
    cmp.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MoviesWithKeywords kw ON rm.title = kw.title
LEFT JOIN 
    SubqueryTitleIndustry cmp ON rm.rank = 1
WHERE 
    rm.rank <= 5
    AND rm.production_year = (SELECT MAX(production_year) FROM RankedMovies)
ORDER BY 
    rm.production_year DESC, 
    rm.title;

This query encompasses a variety of constructs:
- Common Table Expressions (CTEs) to structure the query effectively.
- A `ROW_NUMBER` window function to rank movies based on the number of cast members per production year.
- A `LEFT JOIN` on cast_info, allowing for movies with no cast to still be included.
- A correlated subquery to capture maximum production year while filtering results.
- Use of `STRING_AGG` for aggregating company names associated with each movie into a single, comma-separated string.
- Handling NULL values appropriately with `COALESCE` to ensure the output remains meaningful.
- One `JOIN` specifically targeting `kind_type` to filter for 'Comedy' related movies. 
- The query allows for performance benchmarking by accounting for variation in dataset sizes and structure interactions.
