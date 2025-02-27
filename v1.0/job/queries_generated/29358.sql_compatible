
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        m.production_year > 2000
        AND cn.country_code = 'USA'
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieStats AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names,
        DENSE_RANK() OVER (ORDER BY total_cast DESC) AS rank_by_cast
    FROM 
        RankedMovies
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        aka_names
    FROM 
        MovieStats
    WHERE 
        rank_by_cast <= 10
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.aka_names,
    mi.info AS movie_plot,
    k.keyword AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
