
WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        c.kind AS company_type,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id, m.title, m.production_year, c.kind
),

RoleStatistics AS (
    SELECT 
        r.role AS role_type,
        COUNT(ci.id) AS role_count
    FROM 
        role_type r
    JOIN 
        cast_info ci ON r.id = ci.role_id
    GROUP BY 
        r.role
)

SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.keywords,
    mi.company_type,
    mi.cast_names,
    rs.role_type,
    rs.role_count
FROM 
    MovieInfo mi
LEFT JOIN 
    RoleStatistics rs ON rs.role_type IN (
        SELECT DISTINCT rt.role
        FROM role_type rt 
        JOIN cast_info ci ON rt.id = ci.role_id
        WHERE ci.movie_id IN (SELECT id FROM title WHERE production_year BETWEEN 2000 AND 2020)
    )
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
