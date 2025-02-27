WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        COALESCE(aka.name, 'Unknown') AS person_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        aka_name aka ON ci.person_id = aka.person_id
),
KeywordAggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kw.keywords
    FROM 
        title t
    LEFT JOIN 
        KeywordAggregation kw ON t.id = kw.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    pr.person_name,
    pr.role,
    mt.keywords,
    CASE 
        WHEN mt.production_year < 2000 THEN 'Classic'
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(pr.person_id) OVER (PARTITION BY mt.title ORDER BY pr.role ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_cast
FROM 
    MoviesWithKeywords mt
LEFT JOIN 
    PersonRoles pr ON mt.title_id = pr.movie_id
WHERE 
    mt.keywords IS NOT NULL
    AND (mt.production_year IS NULL OR mt.production_year > 1990)
    AND pr.role IS NOT NULL
ORDER BY 
    mt.production_year DESC, 
    mt.title_rank ASC NULLS LAST;

