
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mcc.company_id) AS production_companies,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mcc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mcc ON t.id = mcc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title, 
        production_year,
        production_companies,
        cast_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT
    trm.title,
    trm.production_year,
    trm.production_companies,
    LISTAGG(DISTINCT trm.cast_names, ', ') WITHIN GROUP (ORDER BY trm.cast_names) AS all_cast_names,
    LISTAGG(DISTINCT trm.keywords, ', ') WITHIN GROUP (ORDER BY trm.keywords) AS all_keywords
FROM 
    TopRankedMovies trm
GROUP BY 
    trm.title, trm.production_year, trm.production_companies
ORDER BY 
    trm.production_year DESC, 
    trm.production_companies DESC;
