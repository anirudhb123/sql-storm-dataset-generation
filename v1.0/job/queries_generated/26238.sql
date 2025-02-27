WITH MovieTitles AS (
    SELECT 
        a.id AS title_id,
        a.title AS title,
        a.production_year,
        a.kind_id,
        k.keyword AS category_keyword
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        ct.kind AS company_type,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.info AS movie_info,
        it.info AS info_type
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
)
SELECT 
    mt.title,
    mt.production_year,
    mt.category_keyword,
    ad.actor_name,
    ad.company_type,
    ad.role_type,
    mi.movie_info,
    COUNT(ad.actor_name) OVER (PARTITION BY mt.title) AS actor_count
FROM 
    MovieTitles mt
LEFT JOIN 
    ActorDetails ad ON mt.title_id = ad.movie_id
LEFT JOIN 
    MovieInfo mi ON mt.title_id = mi.movie_id
WHERE 
    mt.category_keyword IS NOT NULL
ORDER BY 
    mt.production_year DESC, 
    mt.title;
