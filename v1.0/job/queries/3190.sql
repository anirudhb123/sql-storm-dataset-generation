
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        m.name AS company_name, 
        rt.role AS role_name,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, m.name, rt.role 
),
KeywordStats AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(md.company_name, 'Unknown') AS production_company,
        COALESCE(md.role_name, 'No Role') AS role_assigned,
        md.cast_count,
        COALESCE(ks.keywords, 'No Keywords') AS associated_keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordStats ks ON md.movie_id = ks.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.production_company,
    fr.role_assigned,
    fr.cast_count,
    fr.associated_keywords,
    CASE 
        WHEN fr.cast_count > 10 THEN 'Popular'
        WHEN fr.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Niche'
    END AS popularity_category
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC;
