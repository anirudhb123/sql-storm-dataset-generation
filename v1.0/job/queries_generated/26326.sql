WITH Movie_Aggregates AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
Cast_Roles AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
Movies_With_Role_Info AS (
    SELECT 
        ma.movie_id,
        ma.title,
        ma.production_year,
        ma.total_cast,
        ma.keywords,
        ma.total_companies,
        STRING_AGG(DISTINCT cr.role_name || ' (' || cr.role_count || ')', ', ') AS roles
    FROM 
        Movie_Aggregates ma
    LEFT JOIN 
        Cast_Roles cr ON ma.movie_id = cr.movie_id
    GROUP BY 
        ma.movie_id, ma.title, ma.production_year, ma.total_cast, ma.keywords, ma.total_companies
)
SELECT 
    mwri.title,
    mwri.production_year,
    mwri.total_cast,
    mwri.total_companies,
    mwri.keywords,
    mwri.roles
FROM 
    Movies_With_Role_Info mwri
WHERE 
    mwri.total_cast > 5
ORDER BY 
    mwri.production_year DESC,
    mwri.total_cast DESC;
