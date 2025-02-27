WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
distinct_companies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS num_companies
    FROM
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    COALESCE(dc.num_companies, 0) AS num_companies,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    distinct_companies dc ON rm.title = (SELECT title FROM aka_title WHERE movie_id = dc.movie_id)
LEFT JOIN 
    movie_keywords mk ON rm.title = (SELECT at.title FROM aka_title at WHERE at.movie_id = mk.movie_id)
WHERE 
    rm.num_cast_members > 10 AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, rm.num_cast_members DESC
LIMIT 50;

-- Explanation of the constructs used:
-- 1. CTEs: Used to create ranked_movies, distinct_companies, and movie_keywords for various facets of the data.
-- 2. LEFT JOINs: Allow for matching movies with their distinct companies and keywords while preserving movies without matches.
-- 3. Correlated Subqueries: Used within joins to find titles based on movie_id, exploring relationships between tables.
-- 4. STRING_AGG: To concatenate keywords into a readable format for movies.
-- 5. COALESCE: To handle NULLs and provide default values in the final output.
-- 6. ROW_NUMBER: To rank movies based on the number of cast members by year.
-- 7. Complicated predicates: Applying filters for the number of cast members and production year.
