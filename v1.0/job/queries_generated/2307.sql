WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_of_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.num_of_cast,
        RANK() OVER (ORDER BY md.num_of_cast DESC) AS ranking
    FROM movie_details md
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_of_cast,
    tm.ranking,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    COALESCE(ci.kind, 'Unknown') AS company_type
FROM top_movies tm
LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_type ci ON mc.company_type_id = ci.id
WHERE tm.ranking <= 10
ORDER BY tm.ranking, tm.production_year DESC;
