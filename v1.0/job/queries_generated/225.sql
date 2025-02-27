WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order) AS rank,
        COUNT(c.id) OVER (PARTITION BY t.production_year) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        t.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
top_actors AS (
    SELECT 
        actor.person_id,
        actor.name
    FROM 
        actor_details actor
    WHERE 
        actor.movie_count >= 5
),
movie_titles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        string_agg(DISTINCT a.name, ', ') AS actors,
        COALESCE(mc.name, 'Independent') AS company_name
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, mc.name
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mt.actors,
    mt.company_name,
    CASE 
        WHEN rm.cast_count < 5 THEN 'Limited Cast'
        ELSE 'Robust Cast'
    END AS cast_quality,
    COALESCE((
        SELECT 
            COUNT(*) 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = rm.movie_id 
            AND mi.info LIKE '%Award%'
    ), 0) AS awards_count
FROM 
    ranked_movies rm
JOIN 
    movie_titles mt ON rm.movie_id = mt.movie_id
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
