WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Cast') AS cast_names,
        COUNT(DISTINCT m.company_id) AS production_company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
MostPopularKeywords AS (
    SELECT 
        movie_keyword,
        COUNT(*) as keyword_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 5
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_names,
    md.production_company_count,
    mk.movie_keyword,
    mk.keyword_count
FROM 
    MovieDetails md
JOIN 
    MostPopularKeywords mk ON md.movie_keyword = mk.movie_keyword
ORDER BY 
    md.production_year DESC, 
    mk.keyword_count DESC;
