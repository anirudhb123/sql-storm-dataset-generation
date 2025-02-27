WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cmt.kind) AS companies_type,
        JSON_ARRAYAGG(DISTINCT p.name) AS cast_members
    FROM 
        title t
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type cmt ON mc.company_type_id = cmt.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        name p ON ci.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id
    ORDER BY 
        t.production_year DESC
    LIMIT 10
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies_type,
    md.cast_members
FROM 
    movie_details md
WHERE 
    JSON_LENGTH(md.cast_members) > 5
ORDER BY 
    md.production_year DESC;
