WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), movie_details AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_title, rm.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_names,
    md.company_names 
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC;
