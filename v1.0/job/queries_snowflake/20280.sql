WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS total_movies_by_company
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
full_movie_info AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        cd.actor_count,
        cd.role_count,
        mci.company_name,
        mci.company_type,
        COALESCE(md.keyword, 'No Keywords') AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY md.title_id ORDER BY mci.total_movies_by_company DESC) AS company_rank
    FROM 
        movie_details md
    LEFT JOIN 
        cast_details cd ON md.title_id = cd.movie_id
    LEFT JOIN 
        movie_company_info mci ON md.title_id = mci.movie_id
)
SELECT 
    fmi.title_id,
    fmi.title,
    fmi.production_year,
    fmi.actor_count,
    fmi.role_count,
    fmi.company_name,
    fmi.company_type,
    fmi.movie_keyword
FROM 
    full_movie_info fmi
WHERE 
    (fmi.production_year > 2000 AND fmi.actor_count > 1) 
    OR (fmi.company_type IS NOT NULL AND fmi.role_count > 0)
    AND NOT EXISTS (
        SELECT 1 FROM full_movie_info sub
        WHERE sub.title_id = fmi.title_id
        AND sub.company_rank > 2
    )
ORDER BY 
    fmi.production_year DESC, fmi.title;
