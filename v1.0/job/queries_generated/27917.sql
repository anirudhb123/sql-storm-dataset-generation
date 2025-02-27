WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_titles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
keyword_movies AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    c.total_cast_members,
    c.cast_names,
    cm.production_companies,
    km.total_keywords,
    km.keywords
FROM 
    ranked_titles r
LEFT JOIN 
    cast_titles c ON r.title_id = c.movie_id
LEFT JOIN 
    company_movies cm ON r.title_id = cm.movie_id
LEFT JOIN 
    keyword_movies km ON r.title_id = km.movie_id
WHERE 
    r.rank_by_year <= 5
ORDER BY 
    r.production_year DESC, r.title;
