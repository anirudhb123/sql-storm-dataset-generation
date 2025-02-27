WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword,
        rank
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        p.id AS person_id,
        a.name AS actor_name,
        r.role AS role_name
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieSummary AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        tm.keyword,
        STRING_AGG(DISTINCT cd.actor_name || ' as ' || cd.role_name, ', ') AS actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        CastDetails cd ON tm.title_id = cd.movie_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year, tm.keyword
)
SELECT 
    ms.title,
    ms.production_year,
    ms.keyword,
    ms.actors
FROM 
    MovieSummary ms
ORDER BY 
    ms.production_year DESC, ms.title;
