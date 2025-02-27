WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(pi.note) AS avg_person_rating
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
)

SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    md.keywords,
    md.cast_count,
    md.avg_person_rating
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
AND 
    md.cast_count > 2
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
