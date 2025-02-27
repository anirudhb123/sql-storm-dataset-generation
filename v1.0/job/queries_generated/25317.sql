WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.note ORDER BY c.nr_order) AS cast_notes,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.id) AS keywords,
        COUNT(DISTINCT m.id) AS company_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
    HAVING 
        company_count > 2
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_notes,
    md.keywords,
    CASE 
        WHEN md.production_year < 2010 THEN 'Early Era'
        ELSE 'Modern Era'
    END AS era
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
