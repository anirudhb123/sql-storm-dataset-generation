WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        array_agg(DISTINCT c.kind) AS company_types,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    WHERE 
        t.production_year >= 2000  -- Filter for movies from the year 2000 onward
    GROUP BY 
        t.id
),
PersonInfo AS (
    SELECT 
        a.name AS actor_name,
        pi.info AS biography,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') -- Retrieving only biography information
    GROUP BY 
        a.id, pi.info
),
FinalReport AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keywords,
        md.company_types,
        md.cast_count,
        pi.actor_name,
        pi.biography,
        pi.movie_count
    FROM 
        MovieDetails md
    JOIN 
        cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE production_year = md.production_year)
    JOIN 
        aka_name pi ON ci.person_id = pi.person_id
    WHERE 
        pi.name ILIKE '%john%'  -- Filtering for actors with 'john' in their name
)
SELECT 
    movie_title,
    production_year,
    keywords,
    company_types,
    cast_count,
    actor_name,
    biography,
    movie_count
FROM 
    FinalReport
ORDER BY 
    production_year DESC, 
    cast_count DESC;
