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