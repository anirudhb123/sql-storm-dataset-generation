WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    GROUP BY 
        at.title, at.production_year
),
HighRankedMovies AS (
    SELECT 
        title, 
        production_year,
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT(an.name, ' as ', rt.role), ', ') AS roles_list
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_details
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    h.title,
    h.production_year,
    COALESCE(pr.roles_list, 'No Roles') AS roles,
    COALESCE(mo.movie_details, 'No Details') AS details,
    h.company_count
FROM 
    HighRankedMovies h
LEFT JOIN 
    PersonRoles pr ON h.title = (SELECT title FROM aka_title WHERE id = h.title LIMIT 1)
LEFT JOIN 
    MovieInfo mo ON h.production_year = (SELECT production_year FROM aka_title WHERE id = h.title LIMIT 1)
WHERE 
    h.company_count > 0
ORDER BY 
    h.production_year DESC, h.company_count DESC;
