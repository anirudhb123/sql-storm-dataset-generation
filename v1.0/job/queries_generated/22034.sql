WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_roles AS (
    SELECT 
        c.movie_id,
        cr.role AS character_role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type cr ON c.role_id = cr.id
    GROUP BY 
        c.movie_id, cr.role
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mr.character_role, 'Unknown') AS character_role,
        mr.role_count,
        RANK() OVER (ORDER BY rm.production_year DESC, COUNT(DISTINCT c.id) DESC) AS movie_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_roles mr ON rm.movie_id = mr.movie_id
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mr.character_role, mr.role_count
    HAVING 
        COUNT(DISTINCT cc.subject_id) > 0
),
movie_info_and_keywords AS (
    SELECT 
        t.title,
        t.production_year,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    tm.title,
    tm.production_year,
    tm.character_role,
    tm.role_count,
    mk.keywords,
    CASE 
        WHEN tm.production_year IS NULL THEN 'Year Not Specified' 
        ELSE 'Year Specified' 
    END AS year_status,
    CASE 
        WHEN COUNT(DISTINCT c.id) > 5 THEN 'Popular Cast'
        ELSE 'Niche Cast'
    END AS cast_type
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast c ON tm.movie_id = c.movie_id
LEFT JOIN 
    movie_info_and_keywords mk ON tm.title = mk.title AND tm.production_year = mk.production_year
GROUP BY 
    tm.title, tm.production_year, tm.character_role, tm.role_count, mk.keywords
ORDER BY 
    tm.production_year DESC, 
    tm.role_count DESC
LIMIT 20;
