WITH rated_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(r.rating, 'Not Rated') AS rating,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(r.rating, 'Not Rated') ORDER BY m.production_year DESC) AS rn
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN (SELECT 
                    movie_id,
                    STRING_AGG(info, ', ') AS rating
                FROM movie_info 
                WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
                GROUP BY movie_id) r ON m.id = r.movie_id
    WHERE m.production_year >= 2000
),
cast_aggregates AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.rating,
    rm.production_year,
    ca.total_cast,
    ca.cast_members,
    ks.keywords
FROM rated_movies rm
LEFT JOIN cast_aggregates ca ON rm.movie_id = ca.movie_id
LEFT JOIN keyword_summary ks ON rm.movie_id = ks.movie_id
WHERE rm.rn <= 5
ORDER BY rm.rating DESC, rm.production_year DESC;
