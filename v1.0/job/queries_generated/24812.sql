WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CharCount AS (
    SELECT
        c.movie_id,
        SUM(LENGTH(c.name) - LENGTH(REPLACE(c.name, ' ', '')) + 1) AS character_count
    FROM 
        char_name c
    GROUP BY 
        c.movie_id
),
CastRoles AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompCast AS (
    SELECT 
        cc.movie_id,
        MIN(cc.nr_order) AS first_cast_order,
        MAX(cc.nr_order) AS last_cast_order
    FROM 
        cast_info cc
    GROUP BY 
        cc.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        COALESCE(m.company_name, 'Unknown') AS company_name,
        COALESCE(m.keyword, 'No Keywords') AS keyword_summary,
        COALESCE(cc.unique_roles, 0) AS number_of_unique_roles,
        COALESCE(cc.character_count, 0) AS character_count,
        COALESCE(comp.first_cast_order, NULL) AS first_order,
        COALESCE(comp.last_cast_order, NULL) AS last_order
    FROM
        (SELECT 
            mt.movie_id,
            STRING_AGG(DISTINCT cn.name, ', ') AS company_name,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keyword
         FROM 
            movie_companies mt
         LEFT JOIN 
            company_name cn ON mt.company_id = cn.id
         LEFT JOIN 
            movie_keyword mk ON mt.movie_id = mk.movie_id
         LEFT JOIN 
            keyword k ON mk.keyword_id = k.id
         GROUP BY 
            mt.movie_id) AS m
    FULL OUTER JOIN
        CharCount cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        CastRoles cr ON m.movie_id = cr.movie_id
    LEFT JOIN 
        CompCast comp ON m.movie_id = comp.movie_id
)
SELECT 
    md.movie_id,
    md.company_name,
    md.keyword_summary,
    md.number_of_unique_roles,
    md.character_count,
    CASE 
        WHEN md.first_order IS NULL THEN 'No Cast Available' 
        WHEN md.character_count > 1000 THEN 'Epic'
        ELSE 'Regular' 
    END AS movie_type,
    RANK() OVER (ORDER BY md.character_count DESC) AS movie_rank
FROM 
    MovieDetails md
WHERE 
    md.character_count IS NOT NULL
    AND md.character_count > 0
    AND md.keyword_summary IS NOT NULL
ORDER BY 
    movie_rank;
