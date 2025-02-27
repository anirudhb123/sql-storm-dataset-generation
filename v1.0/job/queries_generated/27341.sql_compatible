
WITH MovieCast AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        p.name AS actor_name,
        cc.kind AS cast_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        comp_cast_type cc ON ci.person_role_id = cc.id
    GROUP BY 
        m.id, m.title, p.name, cc.kind
),
MovieCompanies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        c.name AS company_name,
        ct.kind AS company_kind
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        mi.info AS movie_additional_info
    FROM 
        aka_title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    mc.movie_id,
    mc.movie_title,
    STRING_AGG(DISTINCT ac.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT mc.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT mi.movie_additional_info, ', ') AS additional_info,
    STRING_AGG(DISTINCT mc.company_kind, ', ') AS company_types,
    STRING_AGG(DISTINCT ac.keywords, ', ') AS movie_keywords
FROM 
    MovieCast ac
JOIN 
    MovieCompanies mc ON ac.movie_id = mc.movie_id
JOIN 
    MovieInfo mi ON ac.movie_id = mi.movie_id
GROUP BY 
    mc.movie_id, mc.movie_title
ORDER BY 
    mc.movie_title;
