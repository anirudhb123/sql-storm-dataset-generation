WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT i.info || ': ' || mi.info, ', ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_names,
    cd.company_names,
    cd.company_types,
    id.additional_info
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC
LIMIT 100;

This SQL query retrieves detailed information about movies produced after the year 2000, including the title, production year, cast names, associated companies, and additional info, while benchmarking string processing capabilities through the use of string aggregation functions like `GROUP_CONCAT` and `STRING_AGG`. The results are ordered by production year in descending order and limited to the top 100 entries.
