WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS cast,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
PopularKeywords AS (
    SELECT 
        keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast,
    md.keywords,
    pk.keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    PopularKeywords pk ON md.keywords LIKE '%' || pk.keyword || '%'
ORDER BY 
    md.production_year DESC, pk.keyword_count DESC;
