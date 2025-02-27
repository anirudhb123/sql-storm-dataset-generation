WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
popular_actors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
final_results AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.rank,
        pa.actor_name,
        mk.keywords
    FROM 
        ranked_movies rm
    JOIN 
        popular_actors pa ON EXISTS (
            SELECT 1 
            FROM cast_info ci 
            WHERE ci.movie_id = rm.movie_id 
            AND ci.person_id = (SELECT ak.person_id FROM aka_name ak WHERE ak.name = pa.actor_name)
        )
    LEFT JOIN 
        movie_keywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    title,
    production_year,
    rank,
    actor_name,
    keywords
FROM 
    final_results
ORDER BY 
    production_year DESC, rank ASC;
