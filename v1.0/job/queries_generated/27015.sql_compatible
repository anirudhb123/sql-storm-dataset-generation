
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternative_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        c.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info CAST_INFO ON t.id = CAST_INFO.movie_id
    LEFT JOIN 
        name p ON CAST_INFO.person_id = p.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.title, 
        t.production_year, 
        c.name, 
        ct.kind
),
KeywordCount AS (
    SELECT 
        movie_title,
        COUNT(keywords) AS keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)
SELECT 
    md.movie_title,
    md.production_year,
    md.alternative_names,
    kc.keyword_count,
    md.company_name,
    md.company_type,
    md.cast_names
FROM 
    MovieDetails md
JOIN 
    KeywordCount kc ON md.movie_title = kc.movie_title
ORDER BY 
    md.production_year DESC, 
    kc.keyword_count DESC;
