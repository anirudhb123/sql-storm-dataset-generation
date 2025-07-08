
WITH filtered_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title a
    JOIN movie_companies mc ON a.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN movie_info mi ON a.id = mi.movie_id
    JOIN cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year > 2000 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
        AND cn.country_code = 'USA'
    GROUP BY a.id, a.title, a.production_year
), ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM filtered_movies
)
SELECT 
    rm.rank,
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM ranked_movies rm
JOIN cast_info ci ON rm.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
JOIN keyword kw ON mk.keyword_id = kw.id
GROUP BY rm.rank, rm.movie_title, rm.production_year, rm.actor_count
ORDER BY rm.rank
LIMIT 10;
