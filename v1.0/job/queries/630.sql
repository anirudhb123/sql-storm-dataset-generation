WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_name,
        md.keywords,
        COALESCE(c.kind, 'Unknown') AS company_type,
        COUNT(DISTINCT mi.id) AS info_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON mi.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = md.title LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT m.id FROM aka_title m WHERE m.title = md.title LIMIT 1) 
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        md.rn = 1
    GROUP BY 
        md.title, md.production_year, md.actor_name, md.keywords, c.kind
)
SELECT 
    title,
    production_year,
    actor_name,
    keywords,
    company_type,
    info_count
FROM 
    TopMovies
ORDER BY 
    production_year DESC, title ASC
LIMIT 10;
