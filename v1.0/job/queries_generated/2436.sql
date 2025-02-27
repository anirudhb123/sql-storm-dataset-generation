WITH movie_summary AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS rating
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON at.movie_id = mi.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS total_companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name END) AS distributor_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_summary AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.cast_names,
        cs.total_companies,
        cs.distributor_name,
        ms.info_count,
        ms.rating
    FROM 
        movie_summary ms
    LEFT JOIN 
        company_summary cs ON ms.movie_id = cs.movie_id
)

SELECT 
    fs.movie_title,
    fs.production_year,
    COALESCE(fs.total_cast, 0) AS total_cast,
    COALESCE(fs.cast_names, 'No Cast Available') AS cast_names,
    COALESCE(fs.total_companies, 0) AS total_companies,
    COALESCE(fs.distributor_name, 'N/A') AS distributor_name,
    fs.info_count,
    fs.rating
FROM 
    final_summary fs
WHERE 
    fs.info_count > 0
ORDER BY 
    fs.production_year DESC, 
    fs.total_cast DESC;
