WITH title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
cast_details AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
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
    ti.title,
    ti.production_year,
    ti.movie_kind,
    cd.cast_names,
    cd.roles,
    mci.companies,
    mci.company_types,
    ti.keywords
FROM 
    title_info ti
LEFT JOIN 
    cast_details cd ON ti.title_id = cd.movie_id
LEFT JOIN 
    movie_company_info mci ON ti.title_id = mci.movie_id
WHERE 
    ti.production_year > 2000
ORDER BY 
    ti.production_year DESC, ti.title;
