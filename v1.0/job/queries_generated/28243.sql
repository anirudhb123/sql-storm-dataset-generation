WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS alias_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    JOIN 
        aka_title ak_t ON t.id = ak_t.movie_id
    JOIN 
        aka_name ak ON ak_t.id = ak.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        name p ON c.person_id = p.imdb_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    td.title,
    td.production_year,
    td.alias_names,
    td.keywords,
    cast.cast_names,
    cast.roles,
    comp.company_names,
    comp.company_types
FROM 
    TitleDetails td
LEFT JOIN 
    CastDetails cast ON td.title_id = cast.movie_id
LEFT JOIN 
    CompanyInfo comp ON td.title_id = comp.movie_id
ORDER BY 
    td.production_year DESC, td.title;
