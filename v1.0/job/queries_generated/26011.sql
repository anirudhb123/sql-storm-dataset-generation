WITH Recursive_Aka AS (
    SELECT ka.person_id, ka.name, ka.imdb_index, 
           ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY ka.name) AS rnk
    FROM aka_name ka
),
Movie_Aggregates AS (
    SELECT m.id AS movie_id, 
           m.title, 
           m.production_year,
           COUNT(DISTINCT c.person_id) AS cast_count,
           STRING_AGG(DISTINCT CONCAT(n.name, ' (', n.gender, ')'), ', ') AS cast_names
    FROM aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN name n ON c.person_id = n.id
    GROUP BY m.id, m.title, m.production_year
),
Keywords_Aggregate AS (
    SELECT mk.movie_id,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
Company_Aggregates AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
)

SELECT ma.movie_id, 
       ma.title, 
       ma.production_year, 
       ma.cast_count,
       ma.cast_names,
       ka.name AS aka_name,
       ka.imdb_index AS aka_imdb_index,
       ka.rnk AS aka_rank,
       ka.name AS aka_full_name,
       ka.imdb_index AS aka_imdb_index_duplicated,
       k.keywords,
       co.companies
FROM Movie_Aggregates ma
JOIN Recursive_Aka ka ON ma.cast_names LIKE '%' || ka.name || '%'
LEFT JOIN Keywords_Aggregate k ON ma.movie_id = k.movie_id
LEFT JOIN Company_Aggregates co ON ma.movie_id = co.movie_id
WHERE ma.production_year >= 2000
ORDER BY ma.production_year DESC, 
         ma.cast_count DESC, 
         ka.rnk;
