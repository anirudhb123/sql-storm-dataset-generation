
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_size,
        SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        a.title, a.production_year, company_name
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        company_name,
        keyword_count,
        rank_by_cast_size
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.company_name,
    f.keyword_count,
    CASE 
        WHEN f.keyword_count > 10 THEN 'Highly Tagged'
        WHEN f.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Low Tagged'
    END AS tagging_category
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info ci ON f.title = ci.title
WHERE 
    ci.nr_order IS NOT NULL OR ci.person_role_id IS NULL
ORDER BY 
    f.production_year DESC, 
    f.keyword_count DESC;
