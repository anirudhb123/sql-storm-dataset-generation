WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order = 1 AND 
        t.production_year IS NOT NULL
),
filtered_movies AS (
    SELECT 
        rt.aka_id,
        rt.aka_name,
        rt.movie_title,
        rt.production_year,
        CASE 
            WHEN rt.production_year BETWEEN 2000 AND 2010 THEN '2000s' 
            WHEN rt.production_year > 2010 THEN '2011s+' 
            ELSE 'Prior 2000' 
        END AS production_decade
    FROM 
        ranked_titles rt
    WHERE 
        rt.rank_year <= 5
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
comprehensive_info AS (
    SELECT
        f.aka_id,
        f.aka_name,
        f.movie_title,
        f.production_year,
        f.production_decade,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        filtered_movies f
    LEFT JOIN 
        movie_keywords mk ON f.movie_title = mk.movie_id
)
SELECT 
    ci.aka_name AS cast_name,
    ci.movie_title,
    ci.production_year,
    ci.production_decade,
    ci.keywords,
    CASE 
        WHEN ci.production_year IS NULL THEN 'Unknown Year'
        WHEN ci.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_age_category
FROM 
    comprehensive_info ci
WHERE 
    ci.keywords LIKE '%Comedy%' OR 
    ci.keywords LIKE '%Drama%'
ORDER BY 
    ci.production_year DESC NULLS LAST
LIMIT 100;

-- Additional Diagnostic Query to Benchmark Performance
EXPLAIN ANALYZE 
SELECT 
    COUNT(*) AS total_movies 
FROM 
    comprehensive_info ci
WHERE 
    ci.keywords IS NOT NULL
    AND EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = ci.movie_title
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Date')
    );
