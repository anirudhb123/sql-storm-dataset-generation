WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
    HAVING 
        COUNT(cc.id) > 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
CharNameInfo AS (
    SELECT 
        cn.name,
        cn.imdb_id,
        ROW_NUMBER() OVER (ORDER BY cn.name) AS name_rank
    FROM 
        char_name cn
    WHERE 
        cn.imdb_index IS NOT NULL
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    CI.company_name,
    CI.company_type,
    COALESCE(KI.keyword, 'No Keywords') AS keyword,
    KI.keyword_count,
    CN.name AS character_name,
    CN.name_rank
FROM 
    MovieCTE m
LEFT JOIN 
    CompanyInfo CI ON m.movie_id = CI.movie_id AND CI.company_rank = 1
LEFT JOIN 
    KeywordInfo KI ON m.movie_id = KI.movie_id
LEFT JOIN 
    CharNameInfo CN ON CN.imdb_id = (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = m.movie_id LIMIT 1)
WHERE 
    (m.production_year BETWEEN 2000 AND 2023) 
    AND (CI.company_type LIKE '%Production%' OR CI.company_type IS NULL)
ORDER BY 
    m.production_year DESC, 
    m.title;
