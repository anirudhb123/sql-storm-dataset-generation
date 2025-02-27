
WITH
    ranked_titles AS (
        SELECT 
            t.id AS title_id,
            t.title,
            t.production_year,
            t.kind_id,
            RANK() OVER (PARTITION BY t.production_year ORDER BY CHAR_LENGTH(t.title) DESC) AS title_rank
        FROM 
            aka_title t
        WHERE 
            t.production_year IS NOT NULL
            AND t.title IS NOT NULL
    ),
    famous_cast AS (
        SELECT 
            ci.movie_id,
            ci.person_id,
            p.name AS actor_name,
            COALESCE(COUNT(ci.role_id), 0) AS role_count
        FROM 
            cast_info ci
        JOIN 
            aka_name p ON ci.person_id = p.person_id
        WHERE 
            p.name IS NOT NULL
        GROUP BY 
            ci.movie_id, ci.person_id, p.name
        HAVING 
            COUNT(ci.role_id) > 2
    ),
    keyword_summary AS (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    )
SELECT 
    rt.title,
    rt.production_year,
    rt.kind_id,
    fc.actor_name,
    fc.role_count,
    ks.keywords
FROM 
    ranked_titles rt
JOIN 
    famous_cast fc ON rt.title_id = fc.movie_id
LEFT JOIN 
    keyword_summary ks ON rt.title_id = ks.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, CHAR_LENGTH(rt.title) DESC;
