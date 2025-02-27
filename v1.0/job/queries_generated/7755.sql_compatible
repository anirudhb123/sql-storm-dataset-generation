
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        kind_type kt ON mc.company_type_id = kt.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
info_summary AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.company_type,
        m.actors,
        COUNT(DISTINCT p.info) AS info_count
    FROM 
        movie_details m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        person_info p ON m.movie_id = p.person_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, m.company_type, m.actors
)
SELECT 
    movie_id,
    title,
    production_year,
    company_type,
    actors,
    info_count
FROM 
    info_summary
ORDER BY 
    production_year DESC, actors ASC;
