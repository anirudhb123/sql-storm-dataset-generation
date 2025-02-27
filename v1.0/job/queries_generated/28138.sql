WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title AS m
    LEFT JOIN
        cast_info AS c ON m.movie_id = c.movie_id
    LEFT JOIN
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
TopRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names,
        rm.keywords
    FROM
        RankedMovies AS rm
    WHERE
        rm.rank <= 10
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    tr.cast_count,
    tr.aka_names,
    tr.keywords,
    p.info AS director_info
FROM 
    TopRankedMovies AS tr
LEFT JOIN 
    movie_info AS mi ON tr.movie_id = mi.movie_id
LEFT JOIN 
    info_type AS it ON mi.info_type_id = it.id
LEFT JOIN 
    person_info AS p ON p.person_id = (SELECT person_id FROM cast_info WHERE movie_id = tr.movie_id AND person_role_id = (SELECT id FROM role_type WHERE role = 'Director' LIMIT 1) LIMIT 1)
ORDER BY 
    tr.production_year DESC;
