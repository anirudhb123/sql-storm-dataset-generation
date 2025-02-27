WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        CAST(ARRAY_AGG(DISTINCT r.role) AS text[]) AS roles,
        COUNT(DISTINCT p.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
movies_with_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
final_results AS (
    SELECT 
        t.title,
        t.production_year,
        ct.roles,
        ct.actor_count,
        kw.keywords
    FROM 
        ranked_titles t
    LEFT JOIN 
        cast_with_roles ct ON t.title_id = ct.movie_id
    LEFT JOIN 
        movies_with_keywords kw ON t.title_id = kw.movie_id
    WHERE 
        ct.actor_count > 2 
        OR (kw.keywords LIKE '%action%' AND t.production_year > 2000)
        OR (t.production_year IS NULL AND ct.actor_count IS NULL)
)
SELECT 
    title,
    production_year,
    COALESCE(roles, 'No roles assigned') AS roles,
    COALESCE(actor_count, 0) AS actor_count,
    COALESCE(keywords, 'No keywords') AS keywords
FROM 
    final_results
ORDER BY 
    production_year DESC, title ASC
LIMIT 100;
