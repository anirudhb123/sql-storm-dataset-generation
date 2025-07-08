
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.kind, 'Unknown') AS movie_kind,
        COALESCE LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name), 'No Companies') AS companies_involved,
        COALESCE LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name), 'No Actors') AS cast_members
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        kind_type c ON c.id = m.kind_id
    GROUP BY 
        m.id, m.title, m.production_year, c.kind
    ORDER BY 
        m.production_year DESC
), PopularTitles AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        movie_kind, 
        companies_involved, 
        cast_members,
        RANK() OVER (PARTITION BY production_year ORDER BY COUNT(cast_members) DESC) AS cast_rank
    FROM 
        MovieHierarchy
    GROUP BY 
        movie_id, title, production_year, movie_kind, companies_involved, cast_members
)
SELECT 
    movie_id,
    title,
    production_year,
    movie_kind,
    companies_involved,
    cast_members
FROM 
    PopularTitles
WHERE 
    cast_rank <= 5
ORDER BY 
    production_year DESC, cast_rank;
