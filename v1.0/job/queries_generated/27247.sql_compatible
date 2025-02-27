
WITH Recursive_Cast AS (
    SELECT 
        ca.person_id, 
        ca.movie_id, 
        ROW_NUMBER() OVER(PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order
    FROM 
        cast_info ca
    JOIN 
        aka_name an ON an.person_id = ca.person_id
    WHERE 
        an.name LIKE 'John%'
),
Movie_Info AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title,
        mt.kind AS movie_type,
        m.production_year, 
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        title m
    JOIN 
        kind_type mt ON m.kind_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, mt.kind, m.title, m.production_year
),
Top_Movies AS (
    SELECT 
        mi.movie_id, 
        mi.movie_title, 
        mi.movie_type, 
        mi.production_year, 
        mi.keyword_count
    FROM 
        Movie_Info mi
    WHERE 
        mi.keyword_count > 3
    ORDER BY 
        mi.production_year DESC 
    LIMIT 10
)

SELECT 
    rc.person_id, 
    an.name AS actor_name, 
    tm.movie_title, 
    tm.movie_type, 
    tm.production_year, 
    rc.role_order
FROM 
    Recursive_Cast rc
JOIN 
    aka_name an ON rc.person_id = an.person_id
JOIN 
    Top_Movies tm ON rc.movie_id = tm.movie_id
ORDER BY 
    tm.production_year DESC, rc.role_order;
