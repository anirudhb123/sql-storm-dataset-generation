WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY LENGTH(a.title) DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
TopCommonKeywords AS (
    SELECT 
        k.keyword AS common_keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 50
),
PopularActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
HighestRatedMovies AS (
    SELECT 
        title.title AS movie_title,
        m.production_year,
        AVG(CAST(m.info AS FLOAT)) AS average_rating
    FROM 
        movie_info m
    INNER JOIN 
        title ON m.movie_id = title.id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        title.title, m.production_year
)
SELECT 
    rt.movie_title,
    rt.production_year,
    pb.actor_name,
    tck.common_keyword,
    hrm.average_rating
FROM 
    RankedTitles rt
JOIN 
    PopularActors pb ON rt.rank <= 5
JOIN 
    TopCommonKeywords tck ON tck.keyword_count > 10
JOIN 
    HighestRatedMovies hrm ON hrm.movie_title = rt.movie_title
ORDER BY 
    rt.production_year DESC, hrm.average_rating DESC;
