WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS company_names,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast_members,
        COUNT(DISTINCT p.id) AS unique_persons
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        name p ON ci.person_id = p.imdb_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), average_cast AS (
    SELECT 
        AVG(total_cast_members) AS avg_cast_size
    FROM 
        movie_data
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.company_names,
    md.total_cast_members,
    md.unique_persons,
    CASE 
        WHEN md.total_cast_members > avg.avg_cast_size THEN 'Above Average'
        WHEN md.total_cast_members < avg.avg_cast_size THEN 'Below Average'
        ELSE 'Average'
    END AS cast_size_comparison
FROM 
    movie_data md
CROSS JOIN 
    average_cast avg
ORDER BY 
    md.production_year DESC, 
    md.total_cast_members DESC;
