WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(*) AS role_count,
        CASE 
            WHEN MAX(r.role) IS NULL THEN 'No Role'
            ELSE MAX(r.role)
        END AS most_common_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    cr.role_count,
    cr.most_common_role,
    km.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_roles cr ON rm.rank = 1 AND rm.production_year IN (SELECT DISTINCT production_year FROM ranked_movies WHERE rank = 1)
LEFT JOIN 
    keyword_movies km ON rm.title IN (SELECT title FROM aka_title WHERE kind_id = 1)
WHERE 
    rm.production_year >= 2000 
    AND (cr.role_count > 0 OR cr.most_common_role IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;

This SQL query accomplishes the following:
1. Defines a Common Table Expression (CTE) to rank movies by their total number of distinct cast members for each production year.
2. Uses another CTE to aggregate and count roles to determine the most common role per movie.
3. A third CTE collects and concatenates keywords related to each movie.
4. Combines results from these CTEs using outer joins, filtering for movies produced from the year 2000 onwards with specific conditions on roles and keywords.
5. Sorts the final results by production year and total cast count, with semantic corner cases handled (like null checks on roles).
