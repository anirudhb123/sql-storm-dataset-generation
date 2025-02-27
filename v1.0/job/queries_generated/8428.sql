WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieInformation AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT mt.info) AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info_idx mt ON mi.movie_id = mt.movie_id
    GROUP BY 
        mi.movie_id
)

SELECT 
    t.title,
    t.production_year,
    mr.actor_name,
    mr.role_name,
    cd.company_name,
    cd.company_type,
    mi.keywords,
    mi.additional_info
FROM 
    title t
JOIN 
    MovieRoles mr ON t.id = mr.movie_id
LEFT JOIN 
    CompanyDetails cd ON t.id = cd.movie_id
LEFT JOIN 
    MovieInformation mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
