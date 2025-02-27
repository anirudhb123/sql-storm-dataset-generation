WITH TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
CombinedInfo AS (
    SELECT 
        ti.title_id,
        ti.title,
        ti.production_year,
        ai.actor_id,
        ai.name AS actor_name,
        ai.movie_id,
        ai.role AS actor_role,
        ci.company_name,
        ci.company_type,
        ti.movie_keyword
    FROM TitleInfo ti
    LEFT JOIN ActorInfo ai ON ti.title_id = ai.movie_id
    LEFT JOIN CompanyInfo ci ON ti.title_id = ci.movie_id
)
SELECT 
    title,
    production_year,
    ARRAY_AGG(DISTINCT actor_name) AS actors,
    ARRAY_AGG(DISTINCT company_name || ' (' || company_type || ')') AS production_companies,
    ARRAY_AGG(DISTINCT movie_keyword) AS keywords
FROM CombinedInfo
GROUP BY title_id, title, production_year
ORDER BY production_year DESC, title;
