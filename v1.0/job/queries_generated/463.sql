WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        at.title, at.production_year
), 
movie_details AS (
    SELECT 
        rm.title,
        rm.production_year,
        mk.keyword,
        ci.name AS company_name,
        nt.info AS note
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.title LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.title LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.title LIMIT 1)
    LEFT JOIN 
        info_type nt ON mi.info_type_id = nt.id
    WHERE 
        rm.rank_by_cast <= 3
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.keyword, 'No Keyword') AS keyword,
    COALESCE(md.company_name, 'Independent') AS company_name,
    md.note
FROM 
    movie_details md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.title;
