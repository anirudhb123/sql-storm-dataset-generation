WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a_name.name) AS title_rank
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_name a_name ON a_name.person_id IN (
            SELECT 
                person_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.movie_id = at.movie_id
        )
    WHERE 
        k.keyword LIKE '%action%'
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.company_names,
    cd.company_count,
    COUNT(DISTINCT ci.person_id) AS cast_member_count
FROM 
    RankedTitles rt
LEFT JOIN 
    complete_cast cc ON cc.movie_id = rt.title_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = rt.title_id
WHERE 
    rt.title_rank = 1
GROUP BY 
    rt.title, rt.production_year, cd.company_names, cd.company_count
ORDER BY 
    rt.production_year DESC, rt.title;
