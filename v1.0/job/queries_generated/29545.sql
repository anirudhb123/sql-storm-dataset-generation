WITH MovieDetails AS (
    SELECT 
        t.id as title_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN aka_title ak ON t.id = ak.movie_id
    GROUP BY t.id, k.keyword
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        p.id as person_id,
        p.name as actor_name,
        GROUP_CONCAT(DISTINCT ct.kind) AS role_types
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    LEFT JOIN role_type ct ON c.role_id = ct.id
    GROUP BY c.movie_id, p.id
),
FullDetails AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.keyword,
        md.company_names,
        ad.actor_name,
        ad.role_types
    FROM MovieDetails md
    LEFT JOIN ActorDetails ad ON md.title_id = ad.movie_id
)
SELECT 
    title,
    production_year,
    keyword,
    company_names,
    GROUP_CONCAT(DISTINCT actor_name || ' (' || role_types || ')') as cast
FROM FullDetails
GROUP BY title_id, title, production_year, keyword, company_names
ORDER BY production_year DESC, title;
