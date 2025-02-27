
WITH relevant_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Movie')
),

keyworded_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM relevant_movies rm
    JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rm.movie_id, rm.movie_title
),

cast_details AS (
    SELECT 
        rm.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_info
    FROM relevant_movies rm
    JOIN cast_info ci ON rm.movie_id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY rm.movie_id
)

SELECT 
    km.movie_id,
    km.movie_title,
    km.keywords,
    cd.cast_info,
    rm.production_year
FROM keyworded_movies km
JOIN cast_details cd ON km.movie_id = cd.movie_id
JOIN relevant_movies rm ON km.movie_id = rm.movie_id
ORDER BY rm.production_year DESC, km.movie_title;
