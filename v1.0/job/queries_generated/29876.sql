WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        AVG(CASE WHEN ci.role_id = r.id THEN 1 ELSE NULL END) AS average_cast_role
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
PersonStatistics AS (
    SELECT 
        a.id AS person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_acted_in,
        COUNT(DISTINCT p.info_id) AS infos_provided,
        SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS acting_awards
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    LEFT JOIN 
        info_type it ON p.info_type_id = it.id
    LEFT JOIN 
        info_type pi ON pi.id = 1
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    ps.name AS actor_name,
    ps.movies_acted_in,
    ps.infos_provided,
    ps.acting_awards
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    aka_name ps ON ci.person_id = ps.person_id
WHERE 
    ps.movies_acted_in > 10
ORDER BY 
    md.production_year DESC, 
    ps.acting_awards DESC;
