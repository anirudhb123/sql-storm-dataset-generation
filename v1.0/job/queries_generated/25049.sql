WITH MovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CastInfo AS (
    SELECT 
        t.movie_id,
        GROUP_CONCAT(DISTINCT p.name) AS cast_names,
        COUNT(DISTINCT ci.id) AS num_cast_members
    FROM 
        cast_info ci
    JOIN 
        title t ON t.id = ci.movie_id
    JOIN 
        aka_name p ON p.person_id = ci.person_id
    GROUP BY 
        t.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.aka_names,
    mi.keywords,
    ci.cast_names,
    ci.num_cast_members,
    COALESCE(mi.companies, ARRAY[]::text[]) AS companies
FROM 
    MovieInfo mi
LEFT JOIN 
    CastInfo ci ON ci.movie_id = mi.movie_id
ORDER BY 
    mi.production_year DESC, 
    mi.title ASC
LIMIT 100;
