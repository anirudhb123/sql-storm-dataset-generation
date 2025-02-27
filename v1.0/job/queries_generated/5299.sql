WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.id AS cast_id,
        p.id AS person_id,
        p.name AS person_name,
        r.role AS role_name,
        k.keyword AS movie_keyword
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT person_id) AS total_cast,
        STRING_AGG(DISTINCT role_name, ', ') AS roles,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    ad.movie_title,
    ad.production_year,
    ad.total_cast,
    ad.roles,
    ad.keywords
FROM 
    AggregatedData ad
ORDER BY 
    ad.production_year DESC, ad.total_cast DESC
LIMIT 100;
