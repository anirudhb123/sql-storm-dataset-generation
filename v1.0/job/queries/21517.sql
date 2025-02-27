
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(cc.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
),

notable_cast AS (
    SELECT 
        a.name,
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        a.name, c.movie_id, r.role
    HAVING 
        COUNT(*) > 1
),

keyword_movies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

final_results AS (
    SELECT 
        rm.title,
        rm.production_year,
        nc.name AS notable_actor,
        km.keywords,
        rm.cast_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        notable_cast nc ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = nc.movie_id)
    LEFT JOIN 
        keyword_movies km ON rm.title = (SELECT t.title FROM aka_title t WHERE t.id = km.movie_id)
    WHERE 
        rm.rn <= 10 AND
        (rm.production_year IS NOT NULL OR rm.cast_count > 5)
)

SELECT 
    f.title,
    f.production_year,
    COALESCE(f.notable_actor, 'Unknown Actor') AS notable_actor,
    f.keywords,
    f.cast_count
FROM 
    final_results f
WHERE 
    f.keywords LIKE '%' 
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
