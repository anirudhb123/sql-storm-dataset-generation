WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT CONCAT(ca.name, ' (', rt.role, ')') ORDER BY ca.nr_order SEPARATOR ', ') AS cast_info,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS company_info,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    JOIN 
        role_type rt ON ca.role_id = rt.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
InfoTypes AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(ci.info, ', ') AS info_collection
    FROM 
        movie_info mt
    JOIN 
        info_type ci ON mt.info_type_id = ci.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_info,
    md.company_info,
    md.keyword_count,
    it.info_collection
FROM 
    MovieDetails md
LEFT JOIN 
    InfoTypes it ON md.movie_id = it.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
