WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        a.name AS actor_name,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY a.name) AS role_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        at.production_year >= 2000
    AND 
        rc.role IN ('Actor', 'Director')
),
CompanyMovieDetails AS (
    SELECT 
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MovieDetails md
    JOIN 
        complete_cast cc ON md.movie_title = cc.movie_id
    JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    GROUP BY 
        md.movie_title, md.production_year
),
KeywordCount AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
FinalResults AS (
    SELECT 
        c.movie_title,
        c.production_year,
        c.company_count,
        COALESCE(k.keyword_count, 0) AS keyword_count
    FROM 
        CompanyMovieDetails c
    LEFT JOIN 
        KeywordCount k ON c.movie_title = k.movie_id
)
SELECT 
    fr.movie_title,
    fr.production_year,
    fr.company_count,
    fr.keyword_count,
    CASE 
        WHEN fr.company_count > 5 THEN 'High'
        WHEN fr.company_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS company_strength
FROM 
    FinalResults fr
WHERE 
    fr.keyword_count > 3
ORDER BY 
    fr.production_year DESC, fr.company_count DESC;
