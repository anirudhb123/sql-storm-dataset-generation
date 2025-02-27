WITH ActorTitles AS (
    SELECT 
        na.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        CAST(STRING_AGG(DISTINCT kw.keyword, ', ') AS VARCHAR) AS keywords
    FROM 
        aka_name na
    JOIN 
        cast_info ci ON na.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        na.name, at.title, at.production_year, at.kind_id
),
RoleSummary AS (
    SELECT 
        na.name AS actor_name,
        rt.role AS role,
        COUNT(ci.id) AS role_count
    FROM 
        aka_name na
    JOIN 
        cast_info ci ON na.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        na.name, rt.role
),
ProductionInfo AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    GROUP BY 
        at.title, at.production_year
)

SELECT 
    at.actor_name,
    at.movie_title,
    at.production_year,
    at.kind_id,
    at.keywords,
    rs.role,
    rs.role_count,
    pi.company_count,
    pi.info_count
FROM 
    ActorTitles at
JOIN 
    RoleSummary rs ON at.actor_name = rs.actor_name
JOIN 
    ProductionInfo pi ON at.movie_title = pi.movie_title AND at.production_year = pi.production_year
ORDER BY 
    at.actor_name, at.production_year DESC;
