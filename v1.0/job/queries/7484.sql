WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        rt.role,
        ak.name AS actor_name
    FROM 
        title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    WHERE 
        t.production_year > 2000
),
KeywordDetails AS (
    SELECT 
        md.movie_id,
        k.keyword
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        MovieDetails AS md ON mk.movie_id = md.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.role,
    md.actor_name,
    STRING_AGG(kd.keyword, ', ') AS keywords
FROM 
    MovieDetails AS md
LEFT JOIN 
    KeywordDetails AS kd ON md.movie_id = kd.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_name, md.role, md.actor_name
ORDER BY 
    md.production_year DESC, md.title;
