
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_count,
        cd.actor_names,
        mk.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.title) AS global_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    cmi.title,
    cmi.production_year,
    COALESCE(cmi.actor_count, 0) AS number_of_actors,
    COALESCE(cmi.actor_names, 'No Cast') AS actors,
    COALESCE(cmi.keywords, 'No Keywords') AS movie_keywords
FROM 
    CompleteMovieInfo cmi
WHERE 
    cmi.production_year >= 2000
    AND cmi.global_rank <= 50
ORDER BY 
    cmi.production_year DESC, cmi.title;
