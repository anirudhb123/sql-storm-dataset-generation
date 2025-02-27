WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
    GROUP BY 
        t.title, t.production_year, c.name
),
PersonDetails AS (
    SELECT 
        a.name AS actor_name,
        STRING_AGG(DISTINCT CONCAT_WS(' ', p.first_name, p.last_name), ', ') AS full_names,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        name p ON a.name = p.name
    WHERE 
        ci.nr_order < 10  -- Focus on primary cast positions
    GROUP BY 
        a.name
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.keywords,
    pd.actor_name,
    pd.full_names,
    pd.movie_count
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM title WHERE title = md.title LIMIT 1)
JOIN 
    PersonDetails pd ON ci.person_id = (SELECT person_id FROM aka_name WHERE name = pd.actor_name LIMIT 1)
ORDER BY 
    md.production_year DESC, 
    pd.movie_count DESC;
