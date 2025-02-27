
WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS keyword,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
        t.id AS movie_id
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, k.keyword
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalReport AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keyword,
        md.actor_count,
        md.actors_list,
        cd.companies_involved,
        COALESCE(cd.company_count, 0) AS company_count
    FROM 
        MovieData AS md
    LEFT JOIN 
        CompanyData AS cd ON md.movie_id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    keyword,
    actor_count,
    actors_list,
    companies_involved,
    company_count
FROM 
    FinalReport
ORDER BY 
    production_year DESC, actor_count DESC;
