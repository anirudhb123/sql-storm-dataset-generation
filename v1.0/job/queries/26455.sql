WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
Actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        p.gender,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        name p ON a.person_id = p.imdb_id
    GROUP BY 
        c.movie_id, a.name, p.gender
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT co.name, ', ') AS companies,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)
SELECT 
    mt.title AS Movie_Title,
    mt.production_year AS Year_Released,
    mt.movie_keyword AS Keywords,
    a.actor_name AS Lead_Actor,
    a.actor_count AS Number_of_Actors,
    mcd.companies AS Companies_Involved,
    mcd.company_type AS Company_Type
FROM 
    MovieTitles mt
JOIN 
    Actors a ON mt.title_id = a.movie_id
JOIN 
    MovieCompanyDetails mcd ON mt.title_id = mcd.movie_id
WHERE 
    mt.movie_keyword IS NOT NULL
ORDER BY 
    mt.production_year DESC, mt.title;
