WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT na.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
),
movie_companies_summary AS (
    SELECT 
        mc.movie_id,
        CASE 
            WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Yes'
            ELSE 'No'
        END AS has_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.cast_names,
    mcs.has_companies,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mk.keyword_count IS NOT NULL AND mk.keyword_count > 10 THEN 'High'
        ELSE 'Low'
    END AS keyword_density,
    CASE 
        WHEN rank_per_year = 1 THEN 'Most Popular in Year'
        ELSE NULL
    END AS popularity_label
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    movie_companies_summary mcs ON rm.movie_id = mcs.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000
    AND (mcs.has_companies = 'Yes' OR mk.keyword_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
