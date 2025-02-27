WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(c.id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),

top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        k.keyword,
        ct.kind AS company_type
    FROM 
        ranked_movies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        rm.rank <= 10
),

actor_info AS (
    SELECT 
        p.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        title m ON c.movie_id = m.id
)

SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.cast_count AS Cast_Count,
    STRING_AGG(DISTINCT a.actor_name, ', ') AS Actors,
    STRING_AGG(DISTINCT a.role_name, ', ') AS Roles,
    STRING_AGG(DISTINCT tm.keyword, ', ') AS Keywords,
    STRING_AGG(DISTINCT tm.company_type, ', ') AS Company_Types
FROM 
    top_movies tm
LEFT JOIN 
    actor_info a ON tm.movie_id = a.movie_title
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
