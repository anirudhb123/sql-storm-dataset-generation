
WITH MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
RoleInfo AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info cc
    JOIN 
        role_type rt ON cc.role_id = rt.id
    GROUP BY 
        cc.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.aka_names,
    mi.keywords,
    ci.company_names,
    ci.company_types,
    ri.roles
FROM 
    MovieInfo mi
LEFT JOIN 
    CompanyInfo ci ON mi.movie_id = ci.movie_id
LEFT JOIN 
    RoleInfo ri ON mi.movie_id = ri.movie_id
WHERE 
    mi.production_year >= 2000
ORDER BY 
    mi.production_year DESC, mi.title;
