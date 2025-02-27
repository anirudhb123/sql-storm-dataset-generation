WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        rt.role AS role,
        p.name AS person_name,
        cn.name AS company_name,
        km.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
AggregatedData AS (
    SELECT 
        title_id,
        title,
        production_year,
        COUNT(DISTINCT person_name) AS cast_count,
        COUNT(DISTINCT company_name) AS company_count,
        STRING_AGG(DISTINCT role, ', ') AS roles,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        title_id, title, production_year
)

SELECT 
    ad.title_id,
    ad.title,
    ad.production_year,
    ad.cast_count,
    ad.company_count,
    ad.roles,
    ad.keywords
FROM 
    AggregatedData ad
ORDER BY 
    ad.production_year DESC, 
    ad.cast_count DESC;
