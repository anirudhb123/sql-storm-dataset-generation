WITH title_years AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS keyword,
        kt.kind AS kind_type
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
director_appearances AS (
    SELECT 
        a.person_id,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        c.person_role_id IN (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        a.person_id
),
top_directors AS (
    SELECT 
        a.name,
        da.movie_count,
        ROW_NUMBER() OVER (ORDER BY da.movie_count DESC) AS rank
    FROM 
        director_appearances da
    JOIN 
        aka_name a ON da.person_id = a.person_id
),
popular_titles AS (
    SELECT 
        tt.title,
        tt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title_years tt
    JOIN 
        cast_info c ON tt.title_id = c.movie_id
    GROUP BY 
        tt.title, 
        tt.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) >= 5
)
SELECT 
    d.name AS director_name,
    pt.title AS popular_title,
    pt.production_year,
    pt.cast_count,
    ARRAY_AGG(DISTINCT tt.keyword) AS associated_keywords
FROM 
    top_directors d
JOIN 
    movie_companies mc ON d.movie_count >= 3
JOIN 
    popular_titles pt ON pt.production_year BETWEEN 2015 AND 2023
JOIN 
    title_years tt ON tt.production_year = pt.production_year
GROUP BY 
    d.name, 
    pt.title, 
    pt.production_year, 
    pt.cast_count
ORDER BY 
    d.name, 
    pt.production_year DESC;
