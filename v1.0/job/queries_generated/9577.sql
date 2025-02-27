WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        AVG(mr.info) AS avg_rating
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT movie_id, AVG(info::numeric) AS info FROM movie_info GROUP BY movie_id) mr ON t.id = mr.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        avg_rating DESC, cast_count DESC
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY avg_rating DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ak.name AS actor_name,
    ct.kind AS company_type,
    cn.name AS company_name,
    k.keyword
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank, ak.name;
