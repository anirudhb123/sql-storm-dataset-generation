
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM title m
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year BETWEEN 2000 AND 2020
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast_members,
        cast_names,
        keywords
    FROM RankedMovies
    WHERE rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    tm.cast_names,
    tm.keywords,
    LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types,
    LISTAGG(DISTINCT ci.note, ', ') WITHIN GROUP (ORDER BY ci.note) AS cast_notes
FROM TopMovies tm
LEFT JOIN complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.title,
    tm.production_year,
    tm.num_cast_members,
    tm.cast_names,
    tm.keywords
ORDER BY tm.num_cast_members DESC;
