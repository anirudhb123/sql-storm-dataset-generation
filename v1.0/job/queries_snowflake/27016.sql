
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info c ON c.movie_id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id,
        t.title,
        t.production_year
),

TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.total_cast,
        RANK() OVER (ORDER BY rt.total_cast DESC) AS rank
    FROM 
        RankedTitles rt
    WHERE 
        rt.total_cast > 10
)

SELECT 
    t.title,
    t.production_year,
    ak.name AS director_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS production_companies
FROM 
    TopMovies t
JOIN 
    movie_info mi ON t.title_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info = 'Director'
JOIN 
    aka_name ak ON ak.id = mi.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.title_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.title_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    t.title,
    t.production_year,
    ak.name
ORDER BY 
    t.production_year DESC, t.title;
