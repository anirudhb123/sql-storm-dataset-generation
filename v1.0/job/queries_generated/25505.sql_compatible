
WITH MovieTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.id AS movie_id,
        kt.kind AS movie_kind,
        (SELECT COUNT(DISTINCT cc.person_id)
         FROM cast_info cc
         WHERE cc.movie_id = t.id AND cc.role_id IN (SELECT id FROM role_type WHERE role LIKE '%director%')) AS director_count,
        (SELECT COUNT(DISTINCT cc.person_id)
         FROM cast_info cc
         WHERE cc.movie_id = t.id AND cc.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%')) AS actor_count
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
),
UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        mt.movie_title,
        mt.production_year,
        mt.movie_kind,
        mt.director_count,
        mt.actor_count,
        uk.keywords_list
    FROM 
        MovieTitles mt
    LEFT JOIN 
        UniqueKeywords uk ON mt.movie_id = uk.movie_id
)
SELECT 
    cmi.movie_title,
    cmi.production_year,
    cmi.movie_kind,
    cmi.director_count,
    cmi.actor_count,
    COALESCE(CAST(cmi.keywords_list AS text), 'No keywords') AS keywords
FROM 
    CompleteMovieInfo cmi
ORDER BY 
    cmi.production_year DESC,
    cmi.movie_title;
