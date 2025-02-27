
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
)
SELECT 
    MD.title,
    MD.production_year,
    MD.keyword,
    MD.company_type,
    MD.actors,
    MD.info_count
FROM 
    MovieDetails MD
WHERE 
    MD.info_count > 5
ORDER BY 
    MD.production_year DESC;
