WITH RECURSIVE movie_cte AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_cte m ON m.movie_id = t.id 
    WHERE 
        m.production_year < t.production_year
),

cast_with_rank AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.note,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
),

company_movie_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    CAST(COALESCE(cast_count.total_cast, 0) AS INTEGER) AS total_cast,
    COALESCE(cp.company_name, 'Unknown') AS production_company,
    COALESCE(cp.company_type, 'No Type') AS type_of_company,
    ROW_NUMBER() OVER (ORDER BY m.production_year DESC, m.title) AS overall_rank,
    CASE 
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN '21st Century'
        ELSE 'Earlier Work'
    END AS production_period,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
FROM 
    movie_cte m
LEFT JOIN 
    company_movie_info cp ON m.movie_id = cp.movie_id
LEFT JOIN 
    (SELECT 
        mk.movie_id,
        k.keyword
     FROM 
        movie_keyword mk
     JOIN 
        keyword k ON mk.keyword_id = k.id
    ) ki ON m.movie_id = ki.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS total_cast 
     FROM 
        cast_info 
     GROUP BY 
        movie_id
    ) cast_count ON m.movie_id = cast_count.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, cp.company_name, cp.company_type
ORDER BY 
    overall_rank DESC;
