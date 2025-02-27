WITH ranked_titles AS (
    SELECT 
        a.id AS aka_title_id,
        a.title,
        a.production_year,
        a.kind_id,
        t.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS title_rank
    FROM 
        aka_title a
    JOIN 
        kind_type t ON a.kind_id = t.id
    WHERE 
        a.production_year IS NOT NULL
),
aggregated_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.production_year,
    rt.title,
    rt.title_kind,
    ac.total_cast,
    ac.cast_names,
    mk.keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    aggregated_cast ac ON rt.aka_title_id = ac.movie_id
LEFT JOIN 
    movie_keywords mk ON rt.aka_title_id = mk.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title_kind, 
    rt.title;