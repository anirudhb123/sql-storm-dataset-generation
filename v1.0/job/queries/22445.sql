
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.title, t.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cast_roles AS (
    SELECT 
        m.title,
        p.name,
        p.gender,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_title m
        JOIN cast_info ci ON m.id = ci.movie_id
        JOIN name p ON ci.person_id = p.id
        JOIN role_type rt ON ci.role_id = rt.id
    WHERE 
        p.gender IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    mk.keywords_list,
    cr.name AS cast_member,
    cr.role,
    cr.role_order,
    COALESCE(cr.role, 'UNASSIGNED') AS role_description
FROM 
    ranked_movies rm
    LEFT JOIN movie_keywords mk ON mk.movie_id = rm.production_year
    LEFT JOIN cast_roles cr ON cr.title = rm.title
WHERE 
    rm.rank_by_cast <= 3
    AND rm.total_cast > 10
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC, 
    cr.role_order;
