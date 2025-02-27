WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_kind,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY m.production_year DESC) AS hierarchy_level
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    JOIN 
        complete_cast ca ON t.id = ca.movie_id
    JOIN 
        cast_info ci ON ca.subject_id = ci.person_id AND ci.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.company_kind,
        mh.hierarchy_level,
        ROW_NUMBER() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_kind,
    rm.rank
FROM 
    ranked_movies rm
WHERE 
    rm.hierarchy_level = 1
ORDER BY 
    rm.production_year DESC, rm.rank ASC
LIMIT 50;
