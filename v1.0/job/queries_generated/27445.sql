WITH MovieTitleKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS movie_keyword,
        t.production_year
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
), ActorMovieTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND 
        c.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
), MovieInfo AS (
    SELECT 
        t.title AS movie_title,
        mi.info AS movie_info,
        mi.note AS movie_note
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
)
SELECT 
    mtk.movie_title,
    mtk.movie_keyword,
    amt.actor_name,
    mi.movie_info,
    mi.movie_note
FROM 
    MovieTitleKeywords mtk
JOIN 
    ActorMovieTitles amt ON mtk.movie_title = amt.movie_title AND mtk.production_year = amt.production_year
JOIN 
    MovieInfo mi ON mtk.movie_title = mi.movie_title
ORDER BY 
    mtk.movie_title, amt.actor_name;
