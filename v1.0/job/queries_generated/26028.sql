WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        co.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast AS cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name AS ak ON cc.subject_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, co.name, ct.kind
), 
ranking AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.company_name,
        m.company_type,
        m.keywords,
        m.aka_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.movie_title) AS rank
    FROM 
        movie_data AS m
)

SELECT 
    r.rank,
    r.movie_title,
    r.production_year,
    r.company_name,
    r.company_type,
    r.keywords,
    r.aka_names
FROM 
    ranking AS r
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.production_year DESC, r.rank;

This SQL query performs an intricate analysis focusing on movies produced in or after the year 2000. It aggregates keywords and known aliases for each movie, providing a comprehensive view of both the production details and the entities involved. The query includes common table expressions (CTEs) to break down the steps for clarity and efficiency while utilizing various SQL functions like `STRING_AGG` for list aggregation and `ROW_NUMBER` for ranking within production years for added insights.
