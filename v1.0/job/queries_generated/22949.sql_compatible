
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        AVG(ci.nr_order) AS avg_order,
        DENSE_RANK() OVER (PARTITION BY mt.production_year ORDER BY AVG(ci.nr_order) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
), 
FilteredTitles AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 3
), 
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
), 
TitleWithCompanyCount AS (
    SELECT 
        ft.title,
        ft.production_year,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        CompanyCount cc ON ft.title = (SELECT title FROM aka_title WHERE movie_id = cc.movie_id LIMIT 1)
), 
KeywordSearch AS (
    SELECT 
        mt.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE phonetic_code LIKE 'A%')
    GROUP BY 
        mt.title
)
SELECT 
    t.title,
    t.production_year,
    t.company_count,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN t.company_count > 5 THEN 'High Production'
        WHEN t.company_count BETWEEN 3 AND 5 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_category,
    CONCAT(t.title, ' (', t.production_year, ')') AS formatted_title
FROM 
    TitleWithCompanyCount t
LEFT JOIN 
    KeywordSearch ks ON t.title = ks.title
WHERE 
    (t.company_count IS NOT NULL OR ks.keyword_count IS NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = (SELECT movie_id FROM aka_title WHERE title = t.title LIMIT 1)
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info LIKE '%Award%')
        AND mi.info IS NOT NULL
    )
ORDER BY 
    t.production_year DESC, 
    t.company_count DESC
LIMIT 100;
