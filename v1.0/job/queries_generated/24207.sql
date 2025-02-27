WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No cast') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
),
Directors AS (
    SELECT 
        m.id AS movie_id,
        cc.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cc ON m.company_id = cc.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        ct.kind = 'Director'
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    COALESCE(p.keyword, 'No keywords') AS keywords,
    d.company_name AS director_company,
    d.company_type AS director_type
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularKeywords p ON rm.movie_id = p.movie_id
LEFT JOIN 
    Directors d ON rm.movie_id = d.movie_id
WHERE 
    rm.title_rank <= 5
    AND (d.company_name IS NOT NULL OR rm.cast_count > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

