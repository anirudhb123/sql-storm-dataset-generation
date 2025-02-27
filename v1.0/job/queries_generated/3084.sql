WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.name) AS ranked_title
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        k.keyword IN ('Action', 'Drama') AND
        a.name IS NOT NULL
),

CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),

TitleCompanyInfo AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        cm.company_count,
        COALESCE(ti.info, 'N/A') AS title_info 
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovieCounts cm ON rm.title_id = cm.movie_id
    LEFT JOIN 
        movie_info ti ON rm.title_id = ti.movie_id AND ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
)

SELECT 
    tci.title,
    tci.production_year,
    tci.company_count,
    SUM(COALESCE(ti.info IS NOT NULL, 0)) OVER (PARTITION BY tci.production_year) AS director_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
FROM 
    TitleCompanyInfo tci
LEFT JOIN 
    movie_keyword mk ON tci.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tci.company_count IS NOT NULL
GROUP BY 
    tci.title, tci.production_year, tci.company_count
ORDER BY 
    tci.production_year DESC, director_count DESC, tci.title;
