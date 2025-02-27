WITH ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        ak.title AS movie_title,
        ak.production_year,
        r.role AS role_name,
        c.nr_order AS role_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title ak ON c.movie_id = ak.movie_id
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        a.name IS NOT NULL
        AND ak.production_year >= 2000
),
KeywordInfo AS (
    SELECT 
        ak.title,
        k.keyword
    FROM
        aka_title ak
    JOIN
        movie_keyword mk ON ak.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        k.keyword IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        ak.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        aka_title ak ON mc.movie_id = ak.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    ai.actor_name,
    ai.movie_title,
    ai.production_year,
    ai.role_name,
    GROUP_CONCAT(ki.keyword, ', ') AS keywords,
    GROUP_CONCAT(ci.company_name || ' (' || ci.company_type || ')', '; ') AS companies
FROM 
    ActorInfo ai
LEFT JOIN 
    KeywordInfo ki ON ai.movie_title = ki.title
LEFT JOIN 
    CompanyInfo ci ON ai.movie_title = ci.title
GROUP BY 
    ai.actor_name, ai.movie_title, ai.production_year, ai.role_name
ORDER BY 
    ai.production_year DESC, ai.actor_name;
