WITH MovieActorInfo AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        c.movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        r.role AS role_name
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
MovieKeywordInfo AS (
    SELECT 
        m.movie_id, 
        k.keyword 
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
Summary AS (
    SELECT 
        m.movie_id, 
        m.movie_title, 
        m.production_year, 
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords, 
        STRING_AGG(DISTINCT CONCAT_WS(' (', mc.company_name, mc.company_type, ')'), ', ') AS companies
    FROM 
        MovieActorInfo m
    LEFT JOIN 
        MovieKeywordInfo mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanyInfo mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.movie_id, m.movie_title, m.production_year
)
SELECT 
    s.movie_id, 
    s.movie_title, 
    s.production_year, 
    s.keywords, 
    COUNT(DISTINCT a.actor_id) AS actor_count
FROM 
    Summary s
JOIN 
    MovieActorInfo a ON s.movie_id = a.movie_id
GROUP BY 
    s.movie_id, s.movie_title, s.production_year, s.keywords
ORDER BY 
    s.production_year DESC, 
    actor_count DESC;
