WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id
),
PopularActors AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    GROUP BY 
        ka.person_id, ka.name
    HAVING 
        COUNT(c.movie_id) > 5
),
RecentMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year,
        r.kind_id,
        co.name AS company_name
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        r.production_year >= 2020 AND r.rank_by_cast_count <= 10
)
SELECT 
    rm.title AS Movie_Title,
    rm.production_year AS Production_Year,
    rm.company_name AS Producing_Company,
    pa.name AS Popular_Actor,
    pa.movie_count AS Actor_Movie_Count
FROM 
    RecentMovies rm
JOIN 
    PopularActors pa ON rm.movie_id = pa.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.title;
