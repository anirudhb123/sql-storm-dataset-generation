WITH MovieRoles AS (
    SELECT
        m.id AS movie_id,
        t.title AS movie_title,
        c.person_id,
        a.name AS actor_name,
        r.role AS actor_role,
        c.nr_order
    FROM
        aka_title t
    JOIN
        cast_info c ON t.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        t.production_year BETWEEN 2000 AND 2020
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
),
MovieCompanies AS (
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
)
SELECT 
    mr.movie_id,
    mr.movie_title,
    STRING_AGG(DISTINCT mr.actor_name || ' (' || mr.actor_role || ')', ', ') AS cast,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT mc.company_name || ' [' || mc.company_type || ']', ', ') AS companies
FROM 
    MovieRoles mr
LEFT JOIN 
    MovieKeywords mk ON mr.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON mr.movie_id = mc.movie_id
GROUP BY 
    mr.movie_id, mr.movie_title
ORDER BY 
    COUNT(mr.person_id) DESC, mr.movie_title;
