
WITH MovieData AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'box office' THEN mi.info END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS cast_count,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(mo.budget, 'N/A') AS budget,
    COALESCE(mo.box_office, 'N/A') AS box_office,
    md.actor_names
FROM 
    MovieData md
LEFT JOIN 
    CompanyData cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mo ON md.movie_id = mo.movie_id
WHERE 
    md.cast_count > 0
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 100;
