WITH MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_list
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_members
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        cc.movie_id
)

SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    k.keywords_list,
    i.info_list,
    c.cast_members,
    ct.kind AS company_type,
    cn.name AS company_name
FROM 
    title t
LEFT JOIN 
    MovieKeywords k ON t.id = k.movie_id
LEFT JOIN 
    MovieInfo i ON t.id = i.movie_id
LEFT JOIN 
    CompleteCast c ON t.id = c.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
