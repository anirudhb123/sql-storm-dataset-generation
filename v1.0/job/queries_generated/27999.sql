WITH ranked_titles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
cast_details AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ') AS cast_list,
        COUNT(c.id) AS total_cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.movie_keyword,
    cd.cast_list,
    cd.total_cast_members,
    mcd.company_names,
    mcd.company_types
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.id = cd.movie_id
LEFT JOIN 
    movie_company_details mcd ON rt.id = mcd.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC;
