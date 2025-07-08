
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
actors AS (
    SELECT 
        ak.person_id AS person_id,
        ak.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        LISTAGG(DISTINCT m.title, ', ') WITHIN GROUP (ORDER BY m.title) AS movies_starred
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        ak.person_id, ak.name
),
companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        MAX(c.country_code) AS country_of_origin
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
),
titles_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        k.keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    ak.actor_name,
    rm.title,
    rm.production_year,
    co.country_of_origin,
    ak.movie_count,
    COALESCE(tkw.keyword, 'No keyword') AS keyword
FROM 
    ranked_movies rm
JOIN 
    actors ak ON rm.movie_id = ak.person_id  
LEFT JOIN 
    companies co ON rm.movie_id = co.movie_id
LEFT JOIN 
    titles_with_keywords tkw ON rm.movie_id = tkw.movie_id
WHERE 
    ak.movie_count > (
        SELECT 
            AVG(movie_count) 
        FROM 
            actors
    )
    AND rm.rank_in_year <= 3
ORDER BY 
    rm.production_year DESC, ak.movie_count DESC;
