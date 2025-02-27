
WITH MovieRankings AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
KeywordRanking AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MovieCompanies AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.id
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    mr.total_cast,
    mr.cast_names,
    kr.keywords,
    co.companies
FROM 
    MovieRankings mr
LEFT JOIN 
    KeywordRanking kr ON mr.movie_id = kr.movie_id
LEFT JOIN 
    MovieCompanies co ON mr.movie_id = co.movie_id
WHERE 
    mr.production_year >= 2000
ORDER BY 
    mr.total_cast DESC, mr.production_year DESC
FETCH FIRST 50 ROWS ONLY;
