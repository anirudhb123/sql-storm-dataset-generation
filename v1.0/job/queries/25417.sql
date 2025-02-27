WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY LENGTH(m.title) DESC) AS title_rank
    FROM
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
PopularTitles AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        title_rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CastList AS (
    SELECT 
        cd.movie_id,
        STRING_AGG(cd.actor_name || ' as ' || cd.role_type, ', ') AS cast_list
    FROM 
        CastDetails cd
    GROUP BY 
        cd.movie_id
)
SELECT 
    pt.movie_id,
    pt.movie_title,
    pt.production_year,
    cl.cast_list
FROM 
    PopularTitles pt
LEFT JOIN 
    CastList cl ON pt.movie_id = cl.movie_id
ORDER BY 
    pt.production_year DESC, pt.movie_title;
