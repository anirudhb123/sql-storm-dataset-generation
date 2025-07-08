
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        AVG(LENGTH(m.title)) OVER (PARTITION BY m.production_year) AS avg_title_length
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        rm.avg_title_length,
        cm.company_name,
        cm.company_type,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
    LEFT JOIN 
        KeywordMovies km ON rm.movie_id = km.movie_id
    WHERE 
        rm.rank <= 5 OR 
        (rm.production_year >= 2000 AND cm.num_companies IS NOT NULL)
)
SELECT 
    fr.title,
    fr.production_year,
    COALESCE(fr.company_name, 'Independent') AS production_company,
    fr.keywords,
    CASE 
        WHEN LENGTH(fr.title) <= 30 THEN 'Short'
        WHEN LENGTH(fr.title) BETWEEN 31 AND 60 THEN 'Average'
        ELSE 'Long' 
    END AS title_length_category
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC,
    fr.rank ASC;
