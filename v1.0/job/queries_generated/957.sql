WITH ranked_movies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id
),
filtered_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_cast_count <= 5
),
cast_details AS (
    SELECT 
        rm.title_id, 
        a.name AS actor_name, 
        r.role AS role_name
    FROM 
        filtered_movies rm
    JOIN 
        complete_cast cc ON rm.title_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mv.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mv
    JOIN 
        keyword k ON mv.keyword_id = k.id
    GROUP BY 
        mv.movie_id
),
final_results AS (
    SELECT 
        f.title_id,
        f.title,
        f.production_year,
        f.cast_count,
        cd.actor_name,
        cd.role_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        filtered_movies f
    LEFT JOIN 
        cast_details cd ON f.title_id = cd.title_id
    LEFT JOIN 
        movie_keywords mk ON f.title_id = mk.movie_id
)
SELECT 
    fr.title_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.actor_name,
    fr.role_name,
    fr.keywords
FROM 
    final_results fr
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC, 
    fr.title ASC;
