WITH movie_details AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year
), 
company_details AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
), 
keyword_details AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.num_cast_members,
    md.cast_names,
    COALESCE(cd.num_companies, 0) AS num_companies,
    COALESCE(cd.company_names, 'None') AS company_names,
    COALESCE(kd.keywords, 'No keywords') AS keywords
FROM
    movie_details md
LEFT JOIN 
    company_details cd ON md.production_year = cd.movie_id
LEFT JOIN 
    keyword_details kd ON md.production_year = kd.movie_id
ORDER BY 
    md.production_year DESC, md.title;
