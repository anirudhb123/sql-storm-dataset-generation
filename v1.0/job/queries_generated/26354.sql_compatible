
WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),

CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(a.name, ' as ', r.role), ', ') AS cast_members,
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(co.name, ', ') AS companies,
        STRING_AGG(ct.kind, ', ') AS company_types
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
    m.title,
    m.production_year,
    m.keyword,
    c.cast_members,
    c.cast_count,
    p.info AS person_info,
    cp.companies,
    cp.company_types
FROM 
    MovieTitles m
LEFT JOIN 
    CastDetails c ON m.title_id = c.movie_id
LEFT JOIN 
    movie_info p ON m.title_id = p.movie_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
LEFT JOIN 
    MovieCompanies cp ON m.title_id = cp.movie_id
ORDER BY 
    m.production_year DESC, 
    c.cast_count DESC;
