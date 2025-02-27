WITH RECURSIVE Yearly_Production AS (
    SELECT
        T.production_year,
        COUNT(DISTINCT C.person_id) AS total_cast,
        COUNT(DISTINCT M.id) AS total_movies
    FROM
        aka_title T
    JOIN
        cast_info C ON T.id = C.movie_id
    JOIN
        movie_companies MC ON T.id = MC.movie_id
    JOIN
        company_name CN ON MC.company_id = CN.id
    WHERE
        CN.country_code IS NOT NULL
    GROUP BY
        T.production_year
),

Movie_Keywords AS (
    SELECT
        M.id AS movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords
    FROM
        aka_title M
    LEFT JOIN
        movie_keyword MK ON M.id = MK.movie_id
    LEFT JOIN
        keyword K ON MK.keyword_id = K.id
    GROUP BY
        M.id
),

Person_Roles AS (
    SELECT
        P.person_id,
        R.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY P.person_id ORDER BY COUNT(C.movie_id) DESC) AS role_rank
    FROM
        cast_info C
    JOIN
        aka_name P ON C.person_id = P.person_id
    JOIN
        role_type R ON C.role_id = R.id
    GROUP BY
        P.person_id, R.role
)

SELECT
    A.name AS actor_name,
    M.title AS movie_title,
    MK.keywords,
    Y.production_year,
    Y.total_cast,
    Y.total_movies,
    CASE 
        WHEN P.role_name IS NOT NULL THEN P.role_name
        ELSE 'Unknown Role' 
    END AS role_name,
    COUNT(*) OVER (PARTITION BY Y.production_year) AS movies_count_per_year,
    COALESCE(MAX(MK.keywords) FILTER (WHERE Y.total_movies > 0), 'No Keywords') AS popular_keywords
FROM
    aka_name A
JOIN
    cast_info CI ON A.person_id = CI.person_id
JOIN
    aka_title M ON CI.movie_id = M.id
LEFT JOIN
    Movie_Keywords MK ON M.id = MK.movie_id
JOIN
    Yearly_Production Y ON M.production_year = Y.production_year
LEFT JOIN
    Person_Roles P ON A.person_id = P.person_id AND P.role_rank = 1
WHERE
    Y.total_cast > 0
ORDER BY
    Y.production_year DESC, total_movies DESC
OFFSET 0 LIMIT 100;

-- This query combines several advanced SQL constructs:
-- 1. Common Table Expressions (CTEs) to organize complex aggregates and joins logically
-- 2. Recursive CTE as a placeholder to demonstrate capability (not required for this specific query context)
-- 3. Window functions for counting movies per year and identifying primary roles
-- 4. Aggregating strings for keywords associated with movies
-- 5. Incorporation of various types of joins including outer joins and composite joins.
