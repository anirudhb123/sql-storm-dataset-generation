
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies,
        COALESCE(mg.total_info, 0) AS total_info_count
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS total_info 
        FROM 
            movie_info 
        GROUP BY 
            movie_id
    ) mg ON t.id = mg.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
person_roles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    INNER JOIN role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, 
        c.role_id
),
movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title, 
    rm.production_year,
    rm.title_rank,
    rm.total_movies,
    COALESCE(pr.actor_count, 0) AS number_of_actors,
    COALESCE(mkc.keyword_count, 0) AS number_of_keywords,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    STRING_AGG(DISTINCT ak.name, '; ') AS aka_names,
    CASE 
        WHEN COUNT(DISTINCT r.role) > 1 THEN TRUE 
        ELSE FALSE 
    END AS has_multiple_roles
FROM 
    ranked_movies rm
LEFT JOIN 
    person_roles pr ON rm.movie_id = pr.movie_id
LEFT JOIN 
    movie_keyword_count mkc ON rm.movie_id = mkc.movie_id
LEFT JOIN 
    cast_info c ON rm.movie_id = c.movie_id
LEFT JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    rm.title_rank <= 10
GROUP BY 
    rm.title, 
    rm.production_year, 
    rm.title_rank, 
    rm.total_movies,
    pr.actor_count,
    mkc.keyword_count
ORDER BY 
    rm.production_year DESC, 
    rm.title;
