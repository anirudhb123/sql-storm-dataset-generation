WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.info,
        mt.note,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        movie_info AS mt
    LEFT JOIN 
        movie_keyword AS mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, mt.info, mt.note
),
CompanyAssociations AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    ar.person_id,
    ar.role,
    md.info,
    md.keywords,
    ca.companies,
    ca.company_types
FROM 
    RankedTitles AS rt
JOIN 
    ActorRoles AS ar ON rt.title_id = ar.movie_id
JOIN 
    MovieDetails AS md ON rt.title_id = md.movie_id
JOIN 
    CompanyAssociations AS ca ON rt.title_id = ca.movie_id
WHERE 
    rt.title_rank = 1 AND 
    ar.role_rank <= 3
ORDER BY 
    rt.production_year DESC, rt.title;
