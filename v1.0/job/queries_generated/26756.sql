WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(cc.person_id) AS num_cast_members,
        ARRAY_AGG(DISTINCT a.name) AS all_actor_names,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank_by_cast
    FROM 
        title m
    JOIN 
        complete_cast c ON m.id = c.movie_id
    JOIN 
        cast_info cc ON c.subject_id = cc.person_id AND c.movie_id = cc.movie_id
    JOIN 
        aka_name a ON cc.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.num_cast_members,
        rm.all_actor_names,
        k.keyword AS movie_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.rank_by_cast <= 10
)
SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.num_cast_members,
    STRING_AGG(mwk.all_actor_names::text, ', ') AS actor_names,
    STRING_AGG(mwk.movie_keyword, ', ') AS keywords
FROM 
    MoviesWithKeywords mwk
GROUP BY 
    mwk.movie_title, mwk.production_year, mwk.num_cast_members
ORDER BY 
    mwk.production_year DESC, mwk.num_cast_members DESC;
