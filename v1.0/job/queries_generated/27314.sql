WITH movie_statistics AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        m.id, m.title, m.production_year
),
actor_statistics AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        STRING_AGG(DISTINCT i.info, ', ') AS info
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        person_info i ON a.person_id = i.person_id
    GROUP BY 
        a.id, a.name
),
top_movies AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.keywords,
        ms.companies,
        ROW_NUMBER() OVER (ORDER BY ms.total_cast DESC) AS rank
    FROM 
        movie_statistics ms
)
SELECT 
    tm.rank,
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.keywords,
    tm.companies,
    a.actor_name,
    a.movie_count,
    a.movies,
    a.info
FROM 
    top_movies tm
LEFT JOIN 
    actor_statistics a ON a.movie_count > 0
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
