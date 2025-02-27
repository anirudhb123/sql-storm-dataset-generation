WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank,
        COUNT(*) OVER (PARTITION BY a.production_year) as movie_count
    FROM 
        aka_title a
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(m.info, 'No info') AS movie_info
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info m ON c.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    WHERE 
        c.nr_order <= 5
),
company_info AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
    r.title,
    r.production_year,
    a.actor_name,
    a.movie_info,
    c.company_name,
    c.company_type,
    k.keywords
FROM 
    ranked_titles r
LEFT JOIN 
    actor_movies a ON r.id = a.movie_id
LEFT JOIN 
    company_info c ON r.id = c.movie_id
LEFT JOIN 
    keyword_summary k ON r.id = k.movie_id
WHERE 
    r.year_rank = 1 AND 
    r.movie_count > 3
ORDER BY 
    r.production_year DESC, a.actor_name;
