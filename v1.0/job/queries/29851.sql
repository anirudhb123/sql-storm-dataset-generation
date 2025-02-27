
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
TopCharacters AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT (n.name || ' as ' || r.role), ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
CombinedResults AS (
    SELECT 
        t.title,
        t.production_year,
        t.keyword,
        tc.movie_count,
        tc.roles
    FROM 
        RankedTitles t
    LEFT JOIN 
        TopCharacters tc ON POSITION(t.title IN tc.roles) > 0
    WHERE 
        t.title_rank <= 10
)
SELECT 
    production_year,
    COUNT(*) AS title_count,
    STRING_AGG(DISTINCT title) AS titles,
    STRING_AGG(DISTINCT keyword) AS keywords,
    SUM(movie_count) AS total_movies,
    STRING_AGG(DISTINCT roles) AS all_roles
FROM 
    CombinedResults
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
