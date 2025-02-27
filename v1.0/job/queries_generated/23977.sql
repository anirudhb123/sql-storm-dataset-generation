WITH Recursive_Persons AS (
    SELECT 
        a.id, 
        a.person_id, 
        a.name, 
        COUNT(*) OVER (PARTITION BY a.person_id) AS appearance_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.id) AS rn
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL
),
Movies_With_Keywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(*) FILTER (WHERE k.keyword IS NOT NULL) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),
Cast_With_Roles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ct.kind AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
Full_Movie_Details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(p.name, 'Unknown') AS top_actor_name,
        mw.keywords,
        mw.keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        Cast_With_Roles cwr ON m.id = cwr.movie_id AND cwr.role_order = 1
    LEFT JOIN 
        Recursive_Persons p ON cwr.person_id = p.person_id
    LEFT JOIN 
        Movies_With_Keywords mw ON mw.movie_id = m.id
)
SELECT 
    fmd.movie_id,
    fmd.title,
    fmd.top_actor_name,
    fmd.keywords,
    COALESCE(fmd.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN fmd.keyword_count > 5 THEN 'Highly tagged' 
        ELSE 'Less tagged' 
    END AS keyword_association,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = fmd.movie_id) AS total_cast
FROM 
    Full_Movie_Details fmd
WHERE 
    fmd.top_actor_name IS NOT NULL
ORDER BY 
    fmd.total_keywords DESC, 
    fmd.title ASC;

-- Additional complexities:
-- - The use of CTEs to modularize components of the query.
-- - Outer joins that handle NULLs gracefully.
-- - Window functions for ranking and counting.
-- - String aggregation with ARRAY_AGG for keyword collection.
-- - A correlated subquery to count total cast members for each movie.
