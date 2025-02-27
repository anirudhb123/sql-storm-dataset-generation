WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        c.name AS company_name,
        a.name AS actor_name,
        ti.production_year,
        ti.kind_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        title ti ON t.movie_id = ti.id
    JOIN 
        cast_info ci ON ti.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON ti.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON ti.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        ti.id, t.title, c.name, a.name, ti.production_year, ti.kind_id
),
keyword_summary AS (
    SELECT 
        kind_id, 
        COUNT(DISTINCT movie_title) AS movie_count, 
        SUM(keyword_count) AS total_keywords
    FROM 
        movie_details
    GROUP BY 
        kind_id
)
SELECT 
    kt.kind AS movie_type,
    ks.movie_count,
    ks.total_keywords
FROM 
    kind_type kt
JOIN 
    keyword_summary ks ON kt.id = ks.kind_id
ORDER BY 
    ks.movie_count DESC, 
    ks.total_keywords DESC;
