
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(DISTINCT m.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword m ON t.movie_id = m.movie_id
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, c.kind
),
char_name_details AS (
    SELECT 
        cn.name AS character_name,
        cn.imdb_index,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        char_name cn
    JOIN 
        cast_info ci ON cn.id = ci.person_id
    GROUP BY 
        cn.name, cn.imdb_index
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_type,
        md.aka_names,
        md.keyword_count,
        cd.character_name,
        cd.imdb_index,
        cd.movie_count
    FROM 
        movie_details md
    JOIN 
        char_name_details cd ON md.keyword_count > 5 
    ORDER BY 
        md.production_year DESC, md.movie_title
)
SELECT 
    *
FROM 
    final_benchmark
LIMIT 
    100;
