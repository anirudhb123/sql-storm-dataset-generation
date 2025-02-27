WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) OVER (PARTITION BY t.id) AS total_cast,
        RANK() OVER (ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(m.total_cast, 0) AS total_cast,
        (SELECT AVG(rating) FROM movie_info mi WHERE mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) AS avg_rating
    FROM 
        RankedMovies m
    WHERE 
        m.rank_year <= 10
),
InterestingTitles AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.total_cast,
        tm.avg_rating
    FROM 
        TopRatedMovies tm
    WHERE 
        tm.avg_rating IS NOT NULL AND tm.avg_rating > 7.5
)
SELECT 
    it.title,
    it.production_year,
    it.total_cast,
    COALESCE(group_concat(DISTINCT cn.name ORDER BY cn.name), 'No companies') AS companies
FROM 
    InterestingTitles it
LEFT JOIN 
    movie_companies mc ON it.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id 
GROUP BY 
    it.title, it.production_year, it.total_cast
ORDER BY 
    it.production_year DESC;
