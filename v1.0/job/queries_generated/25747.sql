WITH movie_details AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT p.name) AS cast_names
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        name n ON an.person_id = n.imdb_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, ct.kind
),
info_summary AS (
    SELECT 
        movie_id,
        STRING_AGG(info, ', ') AS movie_info
    FROM 
        movie_info m 
    LEFT JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_keyword,
    md.company_type,
    md.cast_names,
    COALESCE(isu.movie_info, 'No Info Available') AS movie_info
FROM 
    movie_details md
LEFT JOIN 
    info_summary isu ON md.movie_id = isu.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
