WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS cast_type,
        c.nr_order,
        n.name AS actor_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id IN (
        SELECT id FROM aka_name WHERE name = 'Tom Hanks'
    )
    JOIN role_type rt ON ci.role_id = rt.id
    JOIN comp_cast_type c ON ci.person_role_id = c.id
    JOIN aka_name n ON ci.person_id = n.person_id
    WHERE t.production_year >= 1990
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        md.keyword,
        cs.companies,
        cs.company_count,
        md.actor_name
    FROM MovieDetails md
    JOIN CompanyStats cs ON md.movie_id = cs.movie_id
    ORDER BY md.production_year DESC, md.title
)
SELECT * FROM FinalOutput;
