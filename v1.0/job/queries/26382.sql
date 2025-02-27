WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind_type,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
), CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
), MovieBenchmark AS (
    SELECT 
        td.title_id,
        td.title,
        td.production_year,
        td.kind_type,
        td.company_count,
        td.company_names,
        cd.actor_count,
        cd.actor_names
    FROM 
        TitleDetails td
    LEFT JOIN 
        CastDetails cd ON td.title_id = cd.movie_id
)
SELECT 
    mb.title_id,
    mb.title,
    mb.production_year,
    mb.kind_type,
    mb.company_count,
    mb.company_names,
    mb.actor_count,
    mb.actor_names,
    CASE 
        WHEN mb.company_count > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS has_company,
    CASE 
        WHEN mb.actor_count > 0 THEN 'YES' 
        ELSE 'NO' 
    END AS has_cast
FROM 
    MovieBenchmark mb
WHERE 
    mb.production_year BETWEEN 2000 AND 2023 
ORDER BY 
    mb.production_year DESC, 
    mb.title ASC;
