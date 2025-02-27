WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
        JOIN role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
movie_detail AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.total_cast,
        cs.roles,
        COUNT(mk.keyword_id) AS total_keywords,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
        LEFT JOIN cast_summary cs ON rm.movie_id = cs.movie_id
        LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cs.total_cast, cs.roles
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.roles,
    md.total_keywords,
    md.keywords
FROM 
    movie_detail md
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.production_year DESC, md.total_cast DESC
LIMIT 50;
