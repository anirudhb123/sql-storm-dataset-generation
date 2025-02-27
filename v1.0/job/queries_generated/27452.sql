WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        COUNT(DISTINCT mc.id) AS company_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT pi.info, ', ') AS additional_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.name, ct.kind, ak.name, ak.imdb_index
    ORDER BY 
        t.production_year DESC, movie_title
)
SELECT 
    movie_title,
    production_year,
    company_name,
    company_type,
    actor_name,
    actor_index,
    company_count,
    keywords,
    additional_info
FROM 
    MovieDetails
WHERE 
    actor_name IS NOT NULL
    AND company_count > 1
ORDER BY 
    production_year DESC, company_count DESC;
