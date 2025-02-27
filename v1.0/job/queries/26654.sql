WITH MovieRanked AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM 
        MovieRanked
    WHERE 
        rank = 1
),

PersonDetails AS (
    SELECT 
        a.person_id,
        a.name,
        pi.info AS additional_info
    FROM 
        aka_name a
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'biography') 
)

SELECT 
    TM.title,
    TM.production_year,
    TM.keyword,
    PD.name AS lead_actor,
    PD.additional_info
FROM 
    TopMovies TM
JOIN 
    cast_info CI ON TM.title_id = CI.movie_id 
JOIN 
    PersonDetails PD ON CI.person_id = PD.person_id
WHERE 
    CI.nr_order = 1  
ORDER BY 
    TM.production_year DESC, 
    TM.cast_count DESC;