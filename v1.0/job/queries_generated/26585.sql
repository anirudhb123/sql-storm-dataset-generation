WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        kt.kind AS kind_name,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    GROUP BY 
        t.id, kt.kind
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        GROUP_CONCAT(DISTINCT co.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieMetrics AS (
    SELECT 
        td.title_id,
        td.title,
        td.production_year,
        td.kind_name,
        cd.total_cast,
        cd.roles,
        co.total_companies,
        co.company_names,
        td.aka_names
    FROM 
        TitleDetails td
    LEFT JOIN 
        CastDetails cd ON td.title_id = cd.movie_id
    LEFT JOIN 
        CompanyDetails co ON td.title_id = co.movie_id
)

SELECT 
    title,
    production_year,
    kind_name,
    total_cast,
    roles,
    total_companies,
    company_names,
    aka_names
FROM 
    MovieMetrics
ORDER BY 
    production_year DESC, title;
