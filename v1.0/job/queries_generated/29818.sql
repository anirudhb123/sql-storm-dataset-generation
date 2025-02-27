WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        m.production_year,
        c.name AS company_name,
        cc.kind AS company_type,
        ARRAY_AGG(DISTINCT CONCAT(p.first_name, ' ', p.last_name)) AS cast_members,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.name) AS company_order
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type cc ON mc.company_type_id = cc.id
    JOIN 
        complete_cast cc2 ON t.id = cc2.movie_id
    JOIN 
        cast_info ci ON cc2.subject_id = ci.person_id
    JOIN 
        aka_name p ON ci.person_id = p.id
    JOIN 
        title m ON t.id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, t.title, m.production_year, c.name, cc.kind
    ORDER BY 
        m.production_year DESC
),
TopMovies AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        MovieHierarchy
)
SELECT 
    movie_title,
    production_year,
    company_name,
    company_type,
    cast_members
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, company_order;

This query retrieves information about the top 10 most recent movies, their production companies, and the cast members. It uses a Common Table Expression (CTE) to recursively build a `MovieHierarchy`, aggregating the cast members for each movie. It ranks the movies based on their production year, finally filtering and ordering the results to produce the desired output.
