WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
KeywordAggregate AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mr.movie_id,
    mr.movie_title,
    mr.production_year,
    mr.actor_name,
    mr.role_name,
    ci.company_name,
    ci.company_type,
    mi.info_count,
    mi.info_details,
    ka.keyword_count,
    ka.keywords
FROM 
    MovieRoles mr
LEFT JOIN 
    CompanyInfo ci ON mr.movie_id = ci.movie_id
LEFT JOIN 
    MovieInfo mi ON mr.movie_id = mi.movie_id
LEFT JOIN 
    KeywordAggregate ka ON mr.movie_id = ka.movie_id
ORDER BY 
    mr.production_year DESC, mr.movie_title;
