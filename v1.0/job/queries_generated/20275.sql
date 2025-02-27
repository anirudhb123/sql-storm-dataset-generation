WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rk
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY at.production_year DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        a.name IS NOT NULL
),
company_info AS (
    SELECT 
        cn.name AS company_name,
        mc.movie_id,
        mc.company_id,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.id) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.name IS NOT NULL
),
keyword_info AS (
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
    rt.title_id,
    rt.title,
    rt.production_year,
    ak.actor_name,
    ci.company_name,
    ki.keywords,
    CASE 
        WHEN ak.actor_rank <= 3 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_category,
    COALESCE(ci.company_name, 'No Company') AS company_assignment
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_movie ak ON rt.title_id = ak.movie_title
LEFT JOIN 
    company_info ci ON rt.title_id = ci.movie_id AND ci.company_rank = 1
LEFT JOIN 
    keyword_info ki ON rt.title_id = ki.movie_id
WHERE 
    rt.rk <= 5
    AND rt.production_year <= 2022
ORDER BY 
    rt.production_year DESC, ak.actor_name ASC NULLS LAST;

-- Supporting Queries for Performance Monitoring
EXPLAIN ANALYZE
SELECT 
    COUNT(*) 
FROM 
    aka_title t
WHERE 
    EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = t.movie_id 
        AND ci.person_role_id IN (
            SELECT role_id FROM role_type WHERE role IN ('Lead', 'Supporting')
        )
    )
    OR 
    NOT EXISTS (
        SELECT 1 
        FROM movie_companies mc 
        WHERE mc.movie_id = t.movie_id 
        AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
    );
