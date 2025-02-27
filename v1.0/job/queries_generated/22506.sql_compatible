
WITH ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM
        aka_title at
    LEFT JOIN
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.movie_id = ci.movie_id
    WHERE
        at.production_year IS NOT NULL
    GROUP BY
        at.id, at.title, at.production_year
),
average_cast AS (
    SELECT 
        AVG(total_cast) AS avg_cast
    FROM
        ranked_movies
),
highest_cast AS (
    SELECT 
        title_id,
        title,
        production_year,
        total_cast,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM
        ranked_movies
    WHERE
        total_cast > (SELECT avg_cast FROM average_cast)
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
final_output AS (
    SELECT 
        h.title AS title,
        h.production_year,
        h.total_cast,
        COALESCE(ARRAY_AGG(k.keyword), ARRAY[]) AS keywords,
        COALESCE(SUM(cr.role_count), 0) AS total_roles,
        CASE WHEN h.total_cast IS NULL THEN 'No cast' ELSE 'Has cast' END AS cast_status,
        CASE 
            WHEN h.total_cast > (SELECT avg_cast FROM average_cast) THEN 'Above Average Cast'
            ELSE 'Below Average Cast' END AS cast_comparison
    FROM 
        highest_cast h
    LEFT JOIN 
        movies_with_keywords k ON h.title_id = k.movie_id
    LEFT JOIN 
        cast_roles cr ON h.title_id = cr.movie_id
    GROUP BY 
        h.title, h.production_year, h.total_cast
)
SELECT *
FROM 
    final_output
ORDER BY 
    total_cast DESC NULLS LAST, title;
