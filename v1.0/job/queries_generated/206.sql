WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS movie_role
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        p.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
complete_info AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.movie_role,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        rt.kind AS movie_kind
    FROM 
        actor_movie_info am
    LEFT JOIN 
        movie_keywords mk ON am.movie_title = mk.movie_id
    LEFT JOIN 
        kind_type rt ON am.kind_id = rt.id
)
SELECT 
    ci.actor_name,
    ci.movie_title,
    ci.production_year,
    ci.movie_role,
    ci.keywords,
    ci.movie_kind,
    CASE 
        WHEN ci.production_year IS NULL THEN 'Unknown Year'
        ELSE ci.production_year::TEXT
    END AS production_year_display,
    EXISTS (
        SELECT 1
        FROM ranked_titles rt
        WHERE rt.title = ci.movie_title 
        AND rt.rank <= 5
    ) AS is_top_ranked
FROM 
    complete_info ci
WHERE 
    ci.movie_role LIKE '%Lead%'
ORDER BY 
    ci.production_year DESC, 
    ci.actor_name;
