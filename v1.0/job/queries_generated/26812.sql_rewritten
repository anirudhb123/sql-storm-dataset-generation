WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopRanked AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        p.name AS person_name,
        r.role AS character_role
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order < 5 
),
MovieAndCast AS (
    SELECT 
        tr.movie_title,
        tr.production_year,
        cd.person_name,
        cd.character_role
    FROM 
        TopRanked tr
    JOIN 
        CastDetails cd ON tr.movie_id = cd.movie_id
)
SELECT 
    mac.movie_title,
    mac.production_year,
    STRING_AGG(mac.person_name || ' as ' || mac.character_role, ', ') AS cast_list
FROM 
    MovieAndCast mac
GROUP BY 
    mac.movie_title, mac.production_year
ORDER BY 
    mac.production_year DESC, mac.movie_title;