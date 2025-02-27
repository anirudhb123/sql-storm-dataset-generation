WITH MovieStats AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        COALESCE(SUM(mk.keyword_id IS NOT NULL), 0) AS total_keywords
    FROM
        aka_title m
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY
        m.id, m.title
), TopMovies AS (
    SELECT
        ms.movie_id,
        ms.title,
        ms.total_cast,
        ms.avg_order,
        ms.total_keywords,
        RANK() OVER (ORDER BY ms.total_cast DESC, ms.avg_order DESC) AS rank
    FROM
        MovieStats ms
)
SELECT
    tm.title,
    tm.total_cast,
    tm.avg_order,
    tm.total_keywords,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_name ak 
     WHERE ak.person_id IN (SELECT c.person_id 
                            FROM cast_info c 
                            WHERE c.movie_id = tm.movie_id)) AS cast_names,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
