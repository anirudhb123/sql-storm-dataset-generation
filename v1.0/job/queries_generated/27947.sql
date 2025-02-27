WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT p.first_name || ' ' || p.last_name, ', ') AS cast_members
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        (SELECT 
            id AS person_id, 
            name AS first_name 
         FROM 
            name 
         WHERE 
            gender = 'M') p ON cc.subject_id = p.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.keywords,
    md.company_names,
    md.aka_names,
    md.cast_members,
    COUNT(cc.id) AS total_cast
FROM 
    movie_data md
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
GROUP BY 
    md.movie_id, md.movie_title, md.production_year, 
    md.keywords, md.company_names, md.aka_names,
    md.cast_members
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
