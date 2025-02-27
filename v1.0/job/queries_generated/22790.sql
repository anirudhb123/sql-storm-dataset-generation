WITH Recursive CTE_MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),

CTE_CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') FILTER (WHERE p.name IS NOT NULL) AS cast_names,
        MAX(CASE WHEN cc.status_id = 1 THEN 'Complete' ELSE 'Incomplete' END) AS cast_status
    FROM 
        complete_cast cc
    JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    LEFT JOIN 
        aka_name p ON c.person_id = p.person_id 
    GROUP BY 
        cc.movie_id
),

CTE_CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id 
    GROUP BY 
        mc.movie_id
),

Final_Selection AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ci.total_cast,
        ci.cast_names,
        ci.cast_status,
        co.total_companies,
        co.company_names,
        COALESCE(mi.info, 'No Info') AS movie_info,
        COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era_classification,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        CTE_CompleteCast ci ON m.id = ci.movie_id
    LEFT JOIN 
        CTE_CompanyInfo co ON m.id = co.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Tagline')
    LEFT JOIN 
        CTE_MovieInfo k ON m.id = k.movie_id AND k.keyword_rank = 1
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_cast,
    f.cast_names,
    f.cast_status,
    f.total_companies,
    f.company_names,
    f.movie_info,
    f.movie_keyword,
    f.era_classification,
    CASE 
        WHEN f.total_cast IS NULL THEN 'No Cast Data'
        ELSE 'Cast Data Available'
    END AS cast_availability,
    CASE 
        WHEN f.total_companies > 5 THEN 'High Production'
        ELSE 'Small Production'
    END AS production_scale
FROM 
    Final_Selection f
WHERE 
    f.era_classification = 'Modern'
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC
LIMIT 50;
