WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        COALESCE(CAST(mci.note AS VARCHAR), 'No Note') AS company_note,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = 1001 -- Assuming 1001 is a type for 'Director' 
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        cb.note,
        level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        role_type rt ON cc.role_id = rt.id
    LEFT JOIN 
        company_name cb ON cb.id = cc.person_id
    WHERE 
        rt.role ILIKE '%Actor%'
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        mh.company_note,
        RANK() OVER (PARTITION BY mh.keyword ORDER BY mh.production_year DESC) AS rank_by_year
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.production_year > 2000
)
SELECT 
    r.title,
    r.production_year,
    r.keyword,
    r.company_note,
    r.rank_by_year,
    CAST((SELECT COUNT(*) FROM ranked_movies r2 WHERE r2.keyword = r.keyword) AS VARCHAR) || ' movies with this keyword' AS keyword_count,
    CASE 
        WHEN r.rank_by_year = 1 THEN 'Top Movie' 
        ELSE 'Not Top Movie' END AS movie_status,
    COALESCE(NULLIF(r.note, ''), 'No additional notes') AS extra_note
FROM 
    ranked_movies r
WHERE 
    r.rank_by_year <= 5
ORDER BY 
    r.keyword, 
    r.production_year DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY; -- Pagination if there are many results

This SQL query uses CTEs for a recursive approach to gather movie information related to companies and actors, combines ranking functions to filter top productions, and uses various conditional expressions and NULL handling to manage data quality and ensure robust results. It also integrates pagination to limit the output, highlighting the complexity and depth of the dataset.
