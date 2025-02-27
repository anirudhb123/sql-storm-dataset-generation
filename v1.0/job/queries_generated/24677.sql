WITH RECURSIVE company_movie_cte AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
cast_role_ranked AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        rk.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        role_type rk ON ci.role_id = rk.id
),
title_movie AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
)
SELECT 
    cm.movie_id,
    cm.company_name,
    cm.company_type,
    GROUP_CONCAT(DISTINCT cr.actor_name) AS actors,
    AVG(CASE WHEN t.production_year >= 2000 THEN 1 ELSE NULL END) AS avg_modern_actors,
    MIN(CASE WHEN tr.title_rank = 1 THEN t.movie_title END) AS recent_title,
    SUM(CASE WHEN t.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    COUNT(DISTINCT cr.role) AS distinct_roles
FROM 
    company_movie_cte cm
LEFT JOIN 
    complete_cast cc ON cm.movie_id = cc.movie_id
LEFT JOIN 
    cast_role_ranked cr ON cc.subject_id = cr.movie_id
LEFT JOIN 
    title_movie t ON cm.movie_id = t.id
GROUP BY 
    cm.movie_id, cm.company_name, cm.company_type
HAVING 
    COUNT(DISTINCT cr.actor_name) > 2
    AND EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = cm.movie_id AND mi.info LIKE '%Award%')
ORDER BY 
    avg_modern_actors DESC, company_name ASC;

### Explanation of the Query:
1. **CTEs**:
   - `company_movie_cte`: Gathers company-related information for each movie.
   - `cast_role_ranked`: Obtains actors and their roles, ranking them within each movie.
   - `title_movie`: Gathers movie titles and their keywords, with a rank to prioritize more recent productions.

2. **Aggregation**:
   - SELECT statement brings together various statistics, including a concatenated actor list, average number of modern actors, minimal recent title based on rank, count of keywords, and distinct role count.

3. **Complex Conditions**:
   - The use of COALESCE to handle NULL keywords, HAVING clause to filter based on actor count, and EXISTS subquery to ensure movies have a related piece of information containing 'Award'.

4. **Ordering**:
   - Results are ordered primarily based on the average of modern actors descending and then alphabetically by company name.

This query captures relationships and aggregates across multiple tables while demonstrating the complexity of modern SQL features.
