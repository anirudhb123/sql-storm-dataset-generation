WITH movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
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
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        m.id, t.title, m.production_year
), ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        companies,
        cast_names,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        movie_info_summary
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.companies,
    rm.cast_names
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC;
