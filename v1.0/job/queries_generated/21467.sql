WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(CASE WHEN ct.kind = 'Director' THEN 'Yes' ELSE 'No' END) AS has_director,
        AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE 0 END) OVER () AS avg_production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ValidTitles AS (
    SELECT 
        title,
        production_year,
        CASE 
            WHEN production_year < (SELECT MIN(production_year) FROM aka_title) THEN 'Before First Movie'
            WHEN production_year > (SELECT MAX(production_year) FROM aka_title) THEN 'After Last Movie'
            ELSE 'Within Range'
        END AS year_status,
        cast_count,
        has_director,
        rn
    FROM 
        RankedMovies
    WHERE 
        cast_count IS NOT NULL AND cast_count > 0
),
FilteredResults AS (
    SELECT *
    FROM ValidTitles
    WHERE year_status = 'Within Range'
    AND (cast_count > (SELECT AVG(cast_count) FROM ValidTitles) OR has_director = 'Yes')
)
SELECT 
    title, 
    production_year,
    CONCAT('This movie ', title, ' was produced in ', production_year, ' and has a cast of ', cast_count, 
           ' with director status: ', has_director, '.') AS movie_summary,
    CASE 
        WHEN production_year = (SELECT MAX(production_year) FROM ValidTitles) THEN 'Most Recent'
        WHEN production_year = (SELECT MIN(production_year) FROM ValidTitles) THEN 'Oldest'
        ELSE NULL
    END AS age_category
FROM 
    FilteredResults
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10 OFFSET 5;

-- Outer join to get companies associated with movies
SELECT 
    mt.title,
    c.name AS company_name,
    ct.kind AS company_type,
    COALESCE(mk.keyword, 'No Keywords') AS keyword_info,
    CASE 
        WHEN mk.id IS NOT NULL THEN 'This movie has keywords'
        ELSE 'This movie has no keywords'
    END AS keyword_status
FROM 
    aka_title mt
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
WHERE 
    (c.country_code IS NULL OR c.country_code <> 'USA')
    AND (ct.kind IS NOT NULL OR ct.kind <> 'Producer')
ORDER BY 
    mt.production_year DESC;
