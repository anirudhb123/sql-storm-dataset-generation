WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN aka_name ak ON mt.id = ak.person_id
    WHERE mt.production_year BETWEEN 2000 AND 2023
    GROUP BY mt.id
),
RoleDistribution AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.role_id) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
TopRoles AS (
    SELECT 
        movie_id,
        role,
        role_count,
        RANK() OVER (PARTITION BY movie_id ORDER BY role_count DESC) AS role_rank
    FROM RoleDistribution
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.company_names,
    tr.role,
    tr.role_count
FROM MovieDetails md
JOIN TopRoles tr ON md.movie_id = tr.movie_id
WHERE tr.role_rank = 1
ORDER BY md.production_year DESC, md.title;
