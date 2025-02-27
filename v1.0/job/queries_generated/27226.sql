WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
TopActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
FilteredMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        a.name AS actor_name,
        rt.movie_keyword
    FROM 
        RankedTitles rt
    JOIN 
        movie_info mi ON rt.title_id = mi.movie_id
    JOIN 
        movie_companies mc ON rt.title_id = mc.movie_id
    JOIN 
        TopActors a ON a.movie_count > 5 
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'BoxOffice') 
        AND rt.rank <= 10
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_name,
    fm.movie_keyword
FROM 
    FilteredMovies fm
WHERE 
    fm.movie_keyword IS NOT NULL
ORDER BY 
    fm.production_year DESC, 
    fm.movie_title;
