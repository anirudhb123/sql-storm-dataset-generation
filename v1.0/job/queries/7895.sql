WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank
    FROM 
        aka_title at
    JOIN 
        movie_info mi ON at.id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND mi.info::float >= 7.5
), 
CastDetails AS (
    SELECT 
        c.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name,
        COALESCE(n.gender, 'U') AS gender
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        name n ON ak.person_id = n.imdb_id
), 
TopRankedMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        cd.actor_name,
        cd.role_name,
        cd.gender
    FROM 
        RankedMovies rm
    JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    tr.title, 
    tr.actor_name, 
    tr.role_name, 
    COUNT(*) OVER (PARTITION BY tr.title) AS actor_count,
    MIN(tr.gender) OVER (PARTITION BY tr.title) AS predominant_gender
FROM 
    TopRankedMovies tr
ORDER BY 
    tr.title, 
    tr.actor_name;
