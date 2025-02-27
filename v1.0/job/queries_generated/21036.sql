WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_by_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
person_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
distinct_company_names AS (
    SELECT DISTINCT 
        cn.name,
        cn.country_code
    FROM 
        company_name cn
    WHERE 
        cn.name IS NOT NULL AND cn.country_code IS NOT NULL
),
movie_keywords_pruned AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        kw.keyword NOT LIKE '%spoiler%'
    GROUP BY 
        mk.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    p.name AS actor_name,
    pmc.movie_count,
    dcn.name AS company_name,
    dcn.country_code,
    mkp.keywords,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN pmc.movie_count > 10 THEN 'Prolific'
        WHEN pmc.movie_count BETWEEN 5 AND 10 THEN 'Active'
        ELSE 'Minor'
    END AS actor_activity_level
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT movie_id FROM complete_cast cc WHERE cc.subject_id = rt.id)
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    person_movie_counts pmc ON pmc.person_id = p.person_id
LEFT JOIN 
    movie_keyword_counts mkc ON mkc.movie_id = rt.id 
LEFT JOIN 
    movie_keywords_pruned mkp ON mkp.movie_id = rt.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rt.id
LEFT JOIN 
    distinct_company_names dcn ON mc.company_id = dcn.id
WHERE 
    rt.rank_by_year <= 3 
    AND (dcn.country_code IS NOT NULL OR dcn.country_code = 'US')
ORDER BY 
    rt.production_year DESC, 
    p.name ASC;

This query:
- Uses Common Table Expressions (CTEs) to rank titles by production year, count movies per person, count keywords per movie, and gather distinct company names.
- Incorporates outer joins to connect actors to the movies and keywords.
- Utilizes a correlated subquery for movies in the `cast_info` table.
- Processes string aggregation for keywords while excluding those containing the word "spoiler."
- Applies a CASE statement to classify actors based on their activity levels, incorporating NULL handling in the joins.
- Filters based on rank and geographical conditions for company names.
- Orders the results to showcase the most recently produced titles first and actors' names alphabetically.
