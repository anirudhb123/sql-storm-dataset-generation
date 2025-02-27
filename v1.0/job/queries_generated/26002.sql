WITH ranked_movies AS (
    SELECT 
        a.id AS aka_title_id,
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000 AND 
        c.country_code = 'USA'
),
final_output AS (
    SELECT 
        rm.aka_title_id,
        rm.title,
        rm.production_year,
        rm.company_name,
        STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
    GROUP BY 
        rm.aka_title_id, rm.title, rm.production_year, rm.company_name
)
SELECT 
    fo.aka_title_id,
    fo.title,
    fo.production_year,
    fo.company_name,
    fo.keywords,
    COALESCE(mi.info, 'No info available') AS movie_info
FROM 
    final_output fo
LEFT JOIN 
    movie_info mi ON fo.aka_title_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'description')
ORDER BY 
    fo.production_year DESC, fo.title;
