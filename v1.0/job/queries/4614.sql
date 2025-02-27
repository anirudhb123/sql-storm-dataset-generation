
WITH MovieRatings AS (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS average_rating
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN (SELECT movie_id, CAST(SUBSTRING(info, 1, 4) AS FLOAT) AS rating FROM movie_info WHERE info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')) r ON m.id = r.movie_id
    GROUP BY m.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(CONCAT(a.name, ' as ', r.role) ORDER BY c.nr_order) AS cast_list
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
KeywordSummary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    m.title,
    COALESCE(mr.average_rating, 0) AS average_rating,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_list, 'No Cast Available') AS cast_list,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM title m
LEFT JOIN MovieRatings mr ON m.id = mr.movie_id
LEFT JOIN CastDetails cd ON m.id = cd.movie_id
LEFT JOIN KeywordSummary ks ON m.id = ks.movie_id
WHERE m.production_year BETWEEN 2000 AND 2023
  AND (mr.average_rating IS NULL OR mr.average_rating >= 7.0)
ORDER BY m.production_year DESC, average_rating DESC;
