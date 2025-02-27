WITH ranked_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),

movies_with_keywords AS (
    SELECT 
        mt.movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, m.title
),

movies_info AS (
    SELECT 
        m.id,
        m.title,
        COALESCE(mi.info, 'No info available') AS movie_info,
        mt.keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        movies_with_keywords mt ON m.movie_id = mt.movie_id
),

total_movies AS (
    SELECT 
        COUNT(*) AS total_count 
    FROM 
        aka_title
),

filtered_movies AS (
    SELECT 
        m.*,
        t.total_count,
        CASE 
            WHEN m.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS movie_type
    FROM 
        movies_info m, total_movies t
    WHERE 
        m.keywords LIKE '%action%'
)

SELECT 
    f.*,
    r.actor_name,
    r.actor_rank
FROM 
    filtered_movies f
LEFT JOIN 
    ranked_cast r ON f.id = r.movie_id
WHERE 
    f.movie_type = 'Modern' 
    AND (f.keywords IS NOT NULL OR f.movie_info IS NOT NULL)
ORDER BY 
    f.title, r.actor_rank
LIMIT 50;
